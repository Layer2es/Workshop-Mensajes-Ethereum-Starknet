// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IStarknetMessaging.sol";

// Define algunos errores personalizados como ejemplo.
// Ahorra mucho espacio usar estos errores personalizados en lugar de cadenas de texto.

error CargaInvalida();

/**
   @title Workshop de Cero a Heroe
   Autor: L2 en Español - SEED LAtam - StarknetEs

*/
contract WorkshopMensajesL1 {

    //
    IStarknetMessaging public _snMessaging;

    /**
       @notice Constructor.

       @param snMessaging La dirección del contrato Starknet Core, responsable
       de la mensajería, en goerli = 0xde29d060D45901Fb19ED6C6e959EB22d8626708e
    */
    constructor(address snMessaging) {
        _snMessaging = IStarknetMessaging(snMessaging);
    }

    /**
       @notice Envía un mensaje al contrato de Starknet.

       @param contractAddress La dirección del contrato en Starknet WorkshopMensajeL2.
       @param selector La función l1_handler del contrato a llamar, en este caso 
       "recibir_mensaje_valor_l1" = "0x726563696269725f6d656e73616a655f76616c6f725f6c31".
       @param payload Los datos serializados que se enviarán.

       @dev Ten en cuenta que Cairo solo entiende felts252.
       Por lo tanto, la serialización en Solidity debe ajustarse. Por ejemplo, un uint256
       debe dividirse en dos uint256 con la parte baja y alta para que Cairo lo comprenda.
    */
    function enviar_Mensaje_Starknet(
        uint256 contractAddress,
        uint256 selector,
        uint256[] memory payload
    )
        external
        payable
    {
        _snMessaging.sendMessageToL2{value: msg.value}(
            contractAddress,
            selector,
            payload
        );
    }


    /**
       @notice Una función simple que envía un mensaje con una carga predefinida.
    */
    function enviar_Mensaje_Valor_Starknet(
        uint256 contractAddress,
        uint256 selector,
        uint256 value
    )
        external
        payable
    {
        uint256[] memory payload = new uint256[](1);
        payload[0] = value;

        _snMessaging.sendMessageToL2{value: msg.value}(
            contractAddress,
            selector,
            payload
        );
    }

    /**
       @notice Consume manualmente un mensaje recibido de L2.

       @param fromAddress Contrato L2 (WorkshopMensajesL2) que ha enviado el mensaje.
       @param payload Carga útil del mensaje utilizada para verificar el hash.

       @dev Un mensaje "recibido" significa que el hash del mensaje está registrado como consumible.
       Se debe proporcionar el contenido del mensaje para que el contrato Starknet Core verifique el hash
       y valide el contenido del mensaje antes de ser consumido.
    */
    function consumir_Mensaje_Starknet(
        uint256 fromAddress,
        uint256[] calldata payload
    )
        external
    {
        // Revertirá si el mensaje no es consumible.
        _snMessaging.consumeMessageFromL2(fromAddress, payload);

        // La llamada anterior devuelve el hash del mensaje (bytes32)
        // que se puede utilizar si es necesario.

        // Puedes usar la carga útil para hacer cosas aquí, ya que ahora sabes que el mensaje es
        // válido y seguro para procesar.
        // Recuerda que la carga útil contiene datos serializados en Cairo. Por lo tanto, debes
        // deserializar la carga útil según los datos que contiene.
    }

    /**
       @notice Ejemplo de consumir un valor recibido de L2 del contrato WorkshopMesajesL2.
    */
    function consumir_Mensaje_Valor_Starknet(
        uint256 fromAddress,
        uint256[] calldata payload
    )
        external
    {
        _snMessaging.consumeMessageFromL2(fromAddress, payload);

        // Esperamos que la carga útil contenga solo un valor felt252 (que es un uint256 en Solidity).
        if (payload.length != 1) {
            revert CargaInvalida();
        }

        uint256 valor = payload[0];
        require(valor > 0, 'Valor_invalido');
    }

    /**
       @notice Ejemplo de consumir una estructura serializada de L2.
    */
    function consumir_Mensaje_Estructura_Starknet(
        uint256 fromAddress,
        uint256[] calldata payload
    )
        external
    {
        _snMessaging.consumeMessageFromL2(fromAddress, payload);

        // Esperamos que la carga útil contenga los campos `a` y `b` de `MyData`.
        if (payload.length != 2) {
            revert CargaInvalida();
        }

        uint256 a = payload[0];
        uint256 b = payload[1];
        require(a > 0 && b > 0, "Valor_invalido");
    }
}
