///////////////////////////////////////////////////////////////////////////////////////////////////
//! L1 (Ethereum).                                                                             ////
//!                                                                                            ////
//! La recepción de los mensajes se realiza utilizando las funciones `l1_handler`.             ////
//! Los mensajes se envían utilizando la llamada al sistema `send_message_to_l1_syscall`.      ////
///////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////
/// Una estructura personalizada, que ya es serializable como `felt252`.                       ////
///                                                                                            ////
/// Para enviar una estructura en la carga útil de un mensaje, solo necesitas asegurarte de    ////
/// que tu estructura sea serializable implementando los traits `Serde`.                       ////  
///////////////////////////////////////////////////////////////////////////////////////////////////

#[derive(Drop, Serde)]
struct MyData {
    a: felt252,
    b: felt252,
}

#[starknet::interface]
trait IContractL1<T> {

    //////////////////////////////////////////////////////////////////////////////////////////////
    /// Envía un mensaje al contrato L1 con un único valor felt252.                           ////
    ///                                                                                       ////
    /// # Argumentos                                                                          ////
    ///                                                                                       ////
    /// * `to_address` - Dirección del contrato en L1.                                        ////
    /// * `value` - Valor que se enviará en la carga útil.                                    ////
    //////////////////////////////////////////////////////////////////////////////////////////////

    fn send_message_value(ref self: T, to_address: starknet::EthAddress, value: felt252);


    //////////////////////////////////////////////////////////////////////////////////////////////
    /// Envía un mensaje al contrato L1 con una estructura serializada.                       ////
    /// Esto se hace automáticamente si tu estructura solo contiene miembros ya serializables.////
    ///                                                                                       ////
    /// # Argumentos                                                                          ////
    ///                                                                                       ////
    /// * `to_address` - Dirección del contrato en L1.                                        ////
    /// * `data` - Datos que se enviarán en la carga útil.                                    ////
    //////////////////////////////////////////////////////////////////////////////////////////////
 
    fn send_message_struct(ref self: T, to_address: starknet::EthAddress, data: MyData);

    }

#[starknet::contract]
mod WorkshopMensajesL2 {
    use super::{IContractL1, MyData};
    use starknet::{EthAddress, SyscallResultTrait};

    #[storage]
    struct Storage {}

    //////////////////////////////////////////////////////////////////////////////////////////////
    /// Maneja un mensaje recibido de L1.                                                     ////
    ///                                                                                       ////
    /// Solo las funciones que están anotadas con `#[l1_handler]` pueden  recibir mensajes    ////  
    /// de L1, ya que el secuenciador ejecutará el código del contrato utilizando un tipo     ////
    /// de transacción específico (`L1HandlerTransaction`) que solo puede ver los puntos      ////
    /// finales anotados como tal.                                                            ////
    ///                                                                                       ////
    /// # Argumentos                                                                          ////
    ///                                                                                       ////
    /// * `from_address` - El contrato de L1 que envía el mensaje (WorkshopMensajesL1).       ////
    /// * `value` - Valor esperado en la carga útil.                                          ////
    ///                                                                                       ////
    /// En producción, siempre debes verificar si `from_address` es                           ////
    /// un contrato al que se le permite enviar mensajes, ya que cualquier el contrato de L1  ////
    /// puede enviar mensajes a cualquier contrato de L2 y viceversa.                         ////
    ///                                                                                       ////
    /// En este ejemplo, se espera que la carga útil sea un único valor `felt` y valor `123`  ////
    //////////////////////////////////////////////////////////////////////////////////////////////

    #[l1_handler]
    fn recibir_mensaje_valor_l1(ref self: ContractState, from_address: felt252, value: felt252) {
        // assert(from_address == ...);
        // Valor fijo para que sea valido == 123

        assert(value == 123, 'Invalid value');
    }

    //////////////////////////////////////////////////////////////////////////////////////////////
    /// Maneja un mensaje recibido de L1.                                                     ////
    ///                                                                                       ////   
    /// En este ejemplo, el manejador espera que los miembros de la estructura sean mayores   ////
    /// que 0.                                                                                ////
    ///                                                                                       ////
    /// # Argumentos                                                                          ////
    ///                                                                                       ////
    /// * `from_address` - El contrato L1 que envía el mensaje.                               ////
    /// * `data` - Datos esperados en la carga útil (automáticamente deserializados por cairo)////
    //////////////////////////////////////////////////////////////////////////////////////////////

    #[l1_handler]
    fn recibir_mensaje_estrucutra_l1(ref self: ContractState, from_address: felt252, data: MyData) {
        // assert(from_address == ...);

        assert(!data.a.is_zero(), 'data.a is invalid');
        assert(!data.b.is_zero(), 'data.b is invalid');
    }

    #[external(v0)]
    impl ContractL1Impl of IContractL1<ContractState> {
        fn send_message_value(ref self: ContractState, to_address: EthAddress, value: felt252) {
            // Observa aquí que "serializamos" el valor `felt`, ya que la carga útil debe ser
            // un `Span<felt>`.
            starknet::send_message_to_l1_syscall(to_address.into(), array![value].span())
                .unwrap_syscall();
        }

        fn send_message_struct(ref self: ContractState, to_address: EthAddress, data: MyData) {
            // Serialización explícita de nuestra estructura `MyData`.
            let mut buf: Array<felt252> = array![];
            data.serialize(ref buf);
            starknet::send_message_to_l1_syscall(to_address.into(), buf.span()).unwrap_syscall();
        }
    }
}
