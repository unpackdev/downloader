// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.16 <0.7.0;


// SmartContract for Fractal Company - All Rights Reserved

//       :::::::::: :::::::::      :::      ::::::::  :::::::::::     :::     :::        
//       :+:        :+:    :+:   :+: :+:   :+:    :+:     :+:       :+: :+:   :+:        
//       +:+        +:+    +:+  +:+   +:+  +:+            +:+      +:+   +:+  +:+        
//       :#::+::#   +#++:++#:  +#++:++#++: +#+            +#+     +#++:++#++: +#+        
//       +#+        +#+    +#+ +#+     +#+ +#+            +#+     +#+     +#+ +#+        
//       #+#        #+#    #+# #+#     #+# #+#    #+#     #+#     #+#     #+# #+#        
//       ###        ###    ### ###     ###  ########      ###     ###     ### ########## 


contract Fractal {
    
    struct Inversor {
        address inversor;
        uint Dia_de_la_inversion;
        uint Inversion_en_WEI;
        bool Esta_Activo;
        string Estado;
    }
    
    // Fractal Founds Wallet (ETH) by default
    address owner = 0xF1a25759385D57fA233a8738911787B01819Cf2C; //missed
    address payable FRACTALFOUNDS = 0x5d8c93EcB794423f1De3DCC6CfB7Bc60b745d238;

    
    // (1st)
    function Invertir_Ahora() external payable {
        require(msg.value > 0);
        uint investment = msg.value;
        
        Buscar_Inversor[msg.sender] = Inversor({
            inversor: msg.sender,
            Dia_de_la_inversion: block.timestamp,
            Inversion_en_WEI: investment,
            Esta_Activo: true,
            Estado: 'Activo'
        });
        
        FRACTALFOUNDS.transfer(msg.value);
    }
    
    // (2nd)
    mapping (address => Inversor) public Buscar_Inversor;
    
    // (3rd)
    function Realizar_Pago(address payable _inversor) external payable {
        require(msg.value > 0);
        _inversor.transfer(msg.value);
    }
    
    // (4th)
    function Cambiar_Direccion_de_Fractal_Founds (address payable _direccion) external {
        require (msg.sender == owner);
        FRACTALFOUNDS = _direccion;
    }
    
    // (5th)
    function Cambiar_Estado(address _inversor) external {
        require(msg.sender == owner);
        if(Buscar_Inversor[_inversor].Esta_Activo == true) {
            Buscar_Inversor[_inversor].Esta_Activo = false;
            Buscar_Inversor[_inversor].Estado = 'Inactivo';
        }
    }
}
// Written by Bloqqe Inc - Bloqqe.com [A Colombian Software Company]
// Colombia(Yopal) - Netherland(Rotterdam)