pragma solidity ^0.4.24;
 /**

 ___________ _______   __ _   _  ________  ___
|  _  | ___ \_   _\ \ / /| | | ||  ___|  \/  |
| | | | |_/ / | |  \ V / | |_| || |__ | .  . |
| | | |    /  | |  /   \ |  _  ||  __|| |\/| |
\ \_/ / |\ \ _| |_/ /^\ \| | | || |___| |  | |
 \___/\_| \_|\___/\/   \/\_| |_/\____/\_|  |_/
                                              
                                              

*/
   
   
   
   
contract Orixhem_Contract {

    address private owner;
    address private orixhem_R=0x3AD2E7C81393a377c3877F948282A8fE9886082a;
    constructor() public{
            owner = msg.sender;
    }
    
 struct persona {
        uint id;
        address billetera;
        string eth;
        string pack;
        uint ref;
        uint acumulado;
        uint acumulado_total;
        uint nivel;
        uint limite_referido;
        uint[] equipo;
        uint pagos;
        
    }
 mapping  (address => persona) private nodo;
 mapping (uint=> persona) public id_nodo;
 
uint ids=1;
uint[] private personas_array;

uint private personascont=0;

bool genesis=false;

    function paquetes(uint _i,uint ref) public payable{
      require(nodo[msg.sender].id==0);
	if (_i == 1) {
        require (msg.value== 0.15 ether);
    send_owner(30000000000000000);
    add(7500000000000000,"0.15","Pack1",ref,1,82500000000000000,18000000000000000,19500000000000000,7500000000000000,3000000000000000,4500000000000000);
   
    } else if (_i == 2) {
        require (msg.value== 0.30 ether);
    send_owner(60000000000000000);
    add(15000000000000000,"0.30","Pack2",ref,2,165000000000000000,36000000000000000,39000000000000000,15000000000000000,6000000000000000,9000000000000000);
    } else if (_i == 3) {
        require (msg.value== 0.60 ether);
        send_owner(120000000000000000);
    add(30000000000000000,"0.60","Pack3",ref,3,330000000000000000,72000000000000000,78000000000000000,30000000000000000,12000000000000000,18000000000000000);


    } 
    else if (_i == 4) {
        require (msg.value== 1.20 ether);
         send_owner(240000000000000000);
        add(60000000000000000,"1.2","Pack4",ref,4,660000000000000000,144000000000000000,156000000000000000,60000000000000000,24000000000000000,36000000000000000);


    } 
    else if (_i == 5) {
        require (msg.value== 2.40 ether);
         send_owner(480000000000000000);
        add(120000000000000000,"2.4","Pack5",ref,5,1320000000000000000,288000000000000000,312000000000000000,120000000000000000,48000000000000000,72000000000000000);


    } 
    else if (_i == 6) {
        require (msg.value== 4 ether);
         send_owner(800000000000000000);
        add(200000000000000000,"4","Pack6",ref,6,2200000000000000000,480000000000000000,520000000000000000,200000000000000000,80000000000000000,120000000000000000);

    } 
    else if (_i == 7) {
        require (msg.value== 7 ether);
         send_owner(1400000000000000000);
        add(350000000000000000,"7","Pack7",ref,7,3850000000000000000,840000000000000000,910000000000000000,350000000000000000,140000000000000000,210000000000000000);


    } 
    else if (_i == 8) {
        require (msg.value== 13 ether);
         send_owner(2600000000000000000);
     add(650000000000000000,"13","Pack8",ref,8,7150000000000000000,1560000000000000000,1690000000000000000,650000000000000000,260000000000000000,390000000000000000);


    } 
    else if (_i == 9) {
        require (msg.value== 26 ether);
         send_owner(5200000000000000000);
    add(1300000000000000000,"26","Pack9",ref,9,14300000000000000000,3120000000000000000,3380000000000000000,1300000000000000000,520000000000000000,780000000000000000);


    } 
    else if (_i == 10) {
        require (msg.value== 52 ether);
         send_owner(10400000000000000000);
    add(2600000000000000000,"52","Pack10",ref,10,28600000000000000000,6240000000000000000,6760000000000000000,2600000000000000000,1040000000000000000,1560000000000000000);


    } 
    else if (_i == 11) {
        require (msg.value== 106 ether);
         send_owner(21200000000000000000);
    add(5300000000000000000,"106","Pack11",ref,11,58300000000000000000,12720000000000000000,13780000000000000000,5300000000000000000,2120000000000000000,3180000000000000000);


    }
   while(hay_pagos()){
       pago_automatico();
   }
        
    
}

    function add(uint _acumulado,string _eth,string _pack,uint _referido,uint _nivel,uint pago50,uint pago10,uint pago10a,uint pago5,uint pago2,uint pago3) private {
        require(buscar_referido(_referido));
        require(!limite_de_referido(_referido));
        persona storage personas=nodo[msg.sender];
        persona storage personas_id=id_nodo[ids];
        
        personas_id.id=ids;
        personas_id.billetera = msg.sender;
        personas_id.eth=_eth;
        personas_id.pack=_pack;
        personas_id.ref=_referido;
        personas_id.acumulado=_acumulado;
        personas_id.acumulado_total=_acumulado;
        personas_id.nivel=_nivel;
        personas_id.pagos=0;
        
        personas.id=ids;
        personas.billetera = msg.sender;
        personas.eth=_eth;
        personas.pack=_pack;
        personas.ref=_referido;
        personas.acumulado=_acumulado;
        personas.acumulado_total=_acumulado;
        personas.nivel=_nivel;
        personas.pagos=0;
        
        personascont++;
        personas_array.push(ids);
        asignar_equipo(_referido,ids);
        asignar_pago(_referido,pago50,pago10,pago10a,pago5,pago2,pago3);
        asignar_referido(_referido);
       // pago_automatico();
        ids=ids+1;
    
    }
    
    function seach_address(address a) view public returns (uint) {
return (nodo[a].id);
    }
    function seach_id(uint a) view public returns (uint, address,string,string) {
return (id_nodo[a].id,id_nodo[a].billetera,id_nodo[a].eth,id_nodo[a].pack);
    }
    function dinero (uint a)view public returns (uint,uint,uint,uint,uint,uint){
        return(id_nodo[a].ref,id_nodo[a].acumulado,id_nodo[a].acumulado_total,id_nodo[a].nivel,id_nodo[a].limite_referido,id_nodo[a].pagos);
    }
    
    function buscar_referido(uint a) private  returns(bool){
        if(!genesis){
            genesis=true;
            return true;
        }else {
            if(id_nodo[a].id!=0 ){
            return true;
        }
        else{
            return false;
        }
        }
        
        
    }
    
    
    function send_owner(uint amount) private {
        orixhem_R.transfer(amount); 
    }
    
    function buscar_familia(uint a)private view returns(uint){
    uint count=0;
    if(id_nodo[a].id!=0){
        count++;
        if(id_nodo[id_nodo[a].ref].id !=0){
            count++;
            if(id_nodo[id_nodo[id_nodo[a].ref].ref].id!=0){
                count++;
            }
        }
    }
    return count;
    }
    function limite_de_referido(uint a) private view returns(bool){
        if(id_nodo[a].limite_referido==3){
            return true;
        }else{
            return false;
        }
    }
    function asignar_referido(uint a) private{
        id_nodo[a].limite_referido= id_nodo[a].limite_referido+1;
    }
    function asignar_equipo (uint a,uint per) private {
       id_nodo[a].equipo.push(per);
    }
    function asignar_pago(uint a,uint _50,uint _10,uint _a10,uint _5,uint _2,uint _3)private  {
        //pago 50%
      uint d=id_nodo[a].id;
        //pago 10%
      uint b=id_nodo[id_nodo[a].ref].id;
        //pago 10%
     uint  c=id_nodo[id_nodo[id_nodo[a].ref].ref].id;
       //pagos acumuladoi
       //TOTAL ACUMULADO IMPORTANTE
       id_nodo[d].acumulado=id_nodo[d].acumulado+_50;
       id_nodo[d].acumulado=id_nodo[d].acumulado-_5;
       id_nodo[d].acumulado=id_nodo[d].acumulado+_2;
       //TOTAL ACUMULADO GLOBAL
         id_nodo[d].acumulado_total=id_nodo[d].acumulado_total+_50;
       id_nodo[d].acumulado_total=id_nodo[d].acumulado_total-_5;
       id_nodo[d].acumulado_total=id_nodo[d].acumulado_total+_2;
       //TOTAL ACUMULADO IMPORTANTE
       id_nodo[b].acumulado=id_nodo[b].acumulado+_10;
       id_nodo[b].acumulado=id_nodo[b].acumulado-_2;
       id_nodo[b].acumulado=id_nodo[b].acumulado+_3;
       //TOTAL ACUMULADO GLOBAL
         id_nodo[b].acumulado_total=id_nodo[b].acumulado_total+_10;
       id_nodo[b].acumulado_total=id_nodo[b].acumulado_total-_2;
       id_nodo[b].acumulado_total=id_nodo[b].acumulado_total+_3;
       //TOTAL ACUMULADO IMPORTANTE
       id_nodo[c].acumulado=id_nodo[c].acumulado+_a10;
       id_nodo[c].acumulado=id_nodo[c].acumulado-_3;
       //TOTAL ACUMULADO GLOBAL
        id_nodo[c].acumulado_total=id_nodo[c].acumulado_total+_a10;
       id_nodo[c].acumulado_total=id_nodo[c].acumulado_total-_3;
}
    function mirar_refidos(uint a) public view returns(uint[]){
    return id_nodo[a].equipo;
}
    function mirar_personas()public view returns(uint[]){
    return personas_array;
}

    function pago_automatico() public {
    for (uint i = 1; i<=personas_array.length; i++){
        uint level=id_nodo[i].nivel;
        uint acum=id_nodo[i].acumulado;
        address direccion=id_nodo[i].billetera;
            if(level ==1){
                if(id_nodo[i].pagos==0 &&acum >= 75000000000000000){
                    send_pays(75000000000000000,direccion);
                    id_nodo[i].pagos=1;
                }
                if(id_nodo[i].pagos==1 && acum>=225000000000000000){
                    send_pays(75000000000000000,direccion);
                    id_nodo[i].pagos=2;
                }
                if(id_nodo[i].pagos==2 && acum>=450000000000000000){
                    id_nodo[i].pagos=0;
                    id_nodo[i].nivel=2;
                    id_nodo[i].eth="0.30";
                    id_nodo[i].pack="Pack2";
                    send_owner(60000000000000000);
                    //resto pago de los caminos
                    id_nodo[i].acumulado=id_nodo[i].acumulado-150000000000000000;
                    //sumo del 30% el 5 que baja
                    id_nodo[i].acumulado_total=id_nodo[i].acumulado_total+15000000000000000;
                    id_nodo[i].acumulado=id_nodo[i].acumulado+15000000000000000;
                    // resto de reinversion 0.30
                    id_nodo[i].acumulado=id_nodo[i].acumulado-300000000000000000;
                    //reinversion a los padres
                    asignar_pago(id_nodo[i].ref,165000000000000000,36000000000000000,39000000000000000,15000000000000000,6000000000000000,9000000000000000);
                }
            }
            if(level ==2){
                if(id_nodo[i].pagos==0 &&acum >= 150000000000000000){
                    send_pays(150000000000000000,direccion);
                    id_nodo[i].pagos=1;
                }
                if(id_nodo[i].pagos==1 && acum>=450000000000000000){
                    send_pays(150000000000000000,direccion);
                    id_nodo[i].pagos=2;
                }
                if(id_nodo[i].pagos==2 && acum>=900000000000000000){
                    id_nodo[i].pagos=0;
                    id_nodo[i].nivel=3;
                    id_nodo[i].eth="0.60";
                    id_nodo[i].pack="Pack3";
                    send_owner(120000000000000000);
                    //resto pago de los caminos
                    id_nodo[i].acumulado=id_nodo[i].acumulado-300000000000000000;
                    //sumo del 30% el 5 que baja
                    id_nodo[i].acumulado_total=id_nodo[i].acumulado_total+12000000000000000;
                    id_nodo[i].acumulado=id_nodo[i].acumulado+12000000000000000;
                    // resto de reinversion 0.60
                    id_nodo[i].acumulado=id_nodo[i].acumulado-600000000000000000;
                    //reinversion a los padres
                    asignar_pago(id_nodo[i].ref,330000000000000000,72000000000000000,78000000000000000,30000000000000000,12000000000000000,18000000000000000);
                }
            }
            if(level ==3){
                if(id_nodo[i].pagos==0 &&acum >= 300000000000000000){
                    send_pays(300000000000000000,direccion);
                    id_nodo[i].pagos=1;
                }
                if(id_nodo[i].pagos==1 && acum>=900000000000000000){
                    send_pays(300000000000000000,direccion);
                    id_nodo[i].pagos=2;
                }
                if(id_nodo[i].pagos==2 && acum>=1800000000000000000){
                    id_nodo[i].pagos=0;
                    id_nodo[i].nivel=4;
                    id_nodo[i].eth="1.2";
                    id_nodo[i].pack="Pack4";
                    send_owner(240000000000000000);
                    //resto pago de los caminos
                    id_nodo[i].acumulado=id_nodo[i].acumulado-600000000000000000;
                    //sumo del 30% el 5 que baja
                    id_nodo[i].acumulado_total=id_nodo[i].acumulado_total+24000000000000000;
                    id_nodo[i].acumulado=id_nodo[i].acumulado+24000000000000000;
                    // resto de reinversion 0.30
                    id_nodo[i].acumulado=id_nodo[i].acumulado-1200000000000000000;
                    //reinversion a los padres
                    asignar_pago(id_nodo[i].ref,660000000000000000,144000000000000000,156000000000000000,60000000000000000,24000000000000000,36000000000000000);
                }
            }
            if(level ==4){
                if(id_nodo[i].pagos==0 &&acum >= 600000000000000000){
                    send_pays(600000000000000000,direccion);
                    id_nodo[i].pagos=1;
                }
                if(id_nodo[i].pagos==1 && acum>=1800000000000000000){
                    send_pays(600000000000000000,direccion);
                    id_nodo[i].pagos=2;
                }
                if(id_nodo[i].pagos==2 && acum>=3600000000000000000){
                    id_nodo[i].pagos=0;
                    id_nodo[i].nivel=5;
                    id_nodo[i].eth="2.4";
                    id_nodo[i].pack="Pack5";
                    send_owner(480000000000000000);
                    //resto pago de los caminos
                    id_nodo[i].acumulado=id_nodo[i].acumulado-1200000000000000000;
                    //sumo del 30% el 5 que baja
                    id_nodo[i].acumulado_total=id_nodo[i].acumulado_total+48000000000000000;
                    id_nodo[i].acumulado=id_nodo[i].acumulado+48000000000000000;
                    // resto de reinversion 0.30
                    id_nodo[i].acumulado=id_nodo[i].acumulado-2400000000000000000;
                    //reinversion a los padres
                    asignar_pago(id_nodo[i].ref,1320000000000000000,288000000000000000,312000000000000000,120000000000000000,48000000000000000,72000000000000000);
                }
            }
            if(level ==5){
                if(id_nodo[i].pagos==0 &&acum >= 1600000000000000000){
                    send_pays(1600000000000000000,direccion);
                    id_nodo[i].pagos=1;
                }
                if(id_nodo[i].pagos==1 && acum>=3600000000000000000){
                    send_pays(1600000000000000000,direccion);
                    id_nodo[i].pagos=2;
                }
                if(id_nodo[i].pagos==2 && acum>=7200000000000000000){
                    id_nodo[i].pagos=0;
                    id_nodo[i].nivel=6;
                    id_nodo[i].eth="4";
                    id_nodo[i].pack="Pack6";
                    send_owner(800000000000000000);
                    //resto pago de los caminos
                    id_nodo[i].acumulado=id_nodo[i].acumulado-3200000000000000000;
                    //sumo del 30% el 5 que baja
                    id_nodo[i].acumulado_total=id_nodo[i].acumulado_total+200000000000000000;
                    id_nodo[i].acumulado=id_nodo[i].acumulado+200000000000000000;
                    // resto de reinversion 0.30
                    id_nodo[i].acumulado=id_nodo[i].acumulado-4000000000000000000;
                    //reinversion a los padres
                    asignar_pago(id_nodo[i].ref,2200000000000000000,480000000000000000,520000000000000000,200000000000000000,80000000000000000,120000000000000000);
                }
            }
            if(level ==6){
                if(id_nodo[i].pagos==0 &&acum >= 2500000000000000000){
                    send_pays(2500000000000000000,direccion);
                    id_nodo[i].pagos=1;
                }
                if(id_nodo[i].pagos==1 && acum>=6000000000000000000){
                    send_pays(2500000000000000000,direccion);
                    id_nodo[i].pagos=2;
                }
                if(id_nodo[i].pagos==2 && acum>=12000000000000000000){
                    id_nodo[i].pagos=0;
                    id_nodo[i].nivel=7;
                    id_nodo[i].eth="7";
                    id_nodo[i].pack="Pack7";
                    send_owner(1400000000000000000);
                    //resto pago de los caminos
                    id_nodo[i].acumulado=id_nodo[i].acumulado-5000000000000000000;
                    //sumo del 30% el 5 que baja
                    id_nodo[i].acumulado_total=id_nodo[i].acumulado_total+350000000000000000;
                    id_nodo[i].acumulado=id_nodo[i].acumulado+350000000000000000;
                    // resto de reinversion 0.30
                    id_nodo[i].acumulado=id_nodo[i].acumulado-7000000000000000000;
                    //reinversion a los padres
                    asignar_pago(id_nodo[i].ref,3850000000000000000,840000000000000000,910000000000000000,350000000000000000,140000000000000000,210000000000000000);
                }
            }
            if(level ==7){
                if(id_nodo[i].pagos==0 &&acum >= 4000000000000000000){
                    send_pays(4000000000000000000,direccion);
                    id_nodo[i].pagos=1;
                }
                if(id_nodo[i].pagos==1 && acum>=10500000000000000000){
                    send_pays(4000000000000000000,direccion);
                    id_nodo[i].pagos=2;
                }
                if(id_nodo[i].pagos==2 && acum>=21000000000000000000){
                    id_nodo[i].pagos=0;
                    id_nodo[i].nivel=8;
                    id_nodo[i].eth="13";
                    id_nodo[i].pack="Pack8";
                    send_owner(2600000000000000000);
                    //resto pago de los caminos
                    id_nodo[i].acumulado=id_nodo[i].acumulado-8000000000000000000;
                    //sumo del 30% el 5 que baja
                    id_nodo[i].acumulado_total=id_nodo[i].acumulado_total+650000000000000000;
                    id_nodo[i].acumulado=id_nodo[i].acumulado+650000000000000000;
                    // resto de reinversion 0.30
                    id_nodo[i].acumulado=id_nodo[i].acumulado-13000000000000000000;
                    //reinversion a los padres
                    asignar_pago(id_nodo[i].ref,7150000000000000000,1560000000000000000,1690000000000000000,650000000000000000,260000000000000000,390000000000000000);
                }
            }
            if(level ==8){
                if(id_nodo[i].pagos==0 &&acum >= 6500000000000000000){
                    send_pays(6500000000000000000,direccion);
                    id_nodo[i].pagos=1;
                }
                if(id_nodo[i].pagos==1 && acum>=19500000000000000000){
                    send_pays(6500000000000000000,direccion);
                    id_nodo[i].pagos=2;
                }
                if(id_nodo[i].pagos==2 && acum>=39000000000000000000){
                    id_nodo[i].pagos=0;
                    id_nodo[i].nivel=9;
                    id_nodo[i].eth="26";
                    id_nodo[i].pack="Pack9";
                    send_owner(5200000000000000000);
                    //resto pago de los caminos
                    id_nodo[i].acumulado=id_nodo[i].acumulado-13000000000000000000;
                    //sumo del 30% el 5 que baja
                    id_nodo[i].acumulado_total=id_nodo[i].acumulado_total+1300000000000000000;
                    id_nodo[i].acumulado=id_nodo[i].acumulado+1300000000000000000;
                    // resto de reinversion 0.30
                    id_nodo[i].acumulado=id_nodo[i].acumulado-26000000000000000000;
                    //reinversion a los padres
                    asignar_pago(id_nodo[i].ref,14300000000000000000,3120000000000000000,3380000000000000000,1300000000000000000,520000000000000000,780000000000000000);
                }
            }
            if(level ==9){
                if(id_nodo[i].pagos==0 &&acum >= 13000000000000000000){
                    send_pays(13000000000000000000,direccion);
                    id_nodo[i].pagos=1;
                }
                if(id_nodo[i].pagos==1 && acum>=39000000000000000000){
                    send_pays(13000000000000000000,direccion);
                    id_nodo[i].pagos=2;
                }
                if(id_nodo[i].pagos==2 && acum>=78000000000000000000){
                    id_nodo[i].pagos=0;
                    id_nodo[i].nivel=10;
                    id_nodo[i].eth="52";
                    id_nodo[i].pack="Pack10";
                     send_owner(10400000000000000000);
                    //resto pago de los caminos
                    id_nodo[i].acumulado=id_nodo[i].acumulado-26000000000000000000;
                    //sumo del 30% el 5 que baja
                    id_nodo[i].acumulado_total=id_nodo[i].acumulado_total+2600000000000000000;
                    id_nodo[i].acumulado=id_nodo[i].acumulado+2600000000000000000;
                    // resto de reinversion 0.30
                    id_nodo[i].acumulado=id_nodo[i].acumulado-52000000000000000000;
                    //reinversion a los padres
                    asignar_pago(id_nodo[i].ref,28600000000000000000,6240000000000000000,6760000000000000000,2600000000000000000,1040000000000000000,1560000000000000000);
                }
            }
            if(level ==10){
                if(id_nodo[i].pagos==0 &&acum >= 25000000000000000000){
                    send_pays(25000000000000000000,direccion);
                    id_nodo[i].pagos=1;
                }
                if(id_nodo[i].pagos==1 && acum>=78000000000000000000){
                    send_pays(25000000000000000000,direccion);
                    id_nodo[i].pagos=2;
                }
                if(id_nodo[i].pagos==2 && acum>=156000000000000000000){
                    id_nodo[i].pagos=0;
                    id_nodo[i].nivel=11;
                    id_nodo[i].eth="106";
                    id_nodo[i].pack="Pack11";
                    send_owner(21200000000000000000);
                    //resto pago de los caminos
                    id_nodo[i].acumulado=id_nodo[i].acumulado-50000000000000000000;
                    //sumo del 30% el 5 que baja
                    id_nodo[i].acumulado_total=id_nodo[i].acumulado_total+5300000000000000000;
                    id_nodo[i].acumulado=id_nodo[i].acumulado+5300000000000000000;
                    // resto de reinversion 0.30
                    id_nodo[i].acumulado=id_nodo[i].acumulado-106000000000000000000;
                    //reinversion a los padres
                    asignar_pago(id_nodo[i].ref,58300000000000000000,12720000000000000000,13780000000000000000,5300000000000000000,2120000000000000000,3180000000000000000);
                }
            }
            if(level ==11){
                if(id_nodo[i].pagos==0 &&acum >= 106000000000000000000){
                    send_pays(106000000000000000000,direccion);
                    id_nodo[i].pagos=1;
                }
                if(id_nodo[i].pagos==1 && acum>=159000000000000000000){
                    send_pays(106000000000000000000,direccion);
                    id_nodo[i].pagos=2;
                }
                if(id_nodo[i].pagos==2 && acum>=318000000000000000000){
                    id_nodo[i].pagos=0;
                    id_nodo[i].nivel=11;
                    id_nodo[i].eth="106";
                    id_nodo[i].pack="Pack11";
                    send_owner(21200000000000000000);
                    //resto pago de los caminos
                    id_nodo[i].acumulado=id_nodo[i].acumulado-212000000000000000000;
                    //sumo del 30% el 5 que baja
                    id_nodo[i].acumulado_total=id_nodo[i].acumulado_total+5300000000000000000;
                    id_nodo[i].acumulado=id_nodo[i].acumulado+5300000000000000000;
                    // resto de reinversion 0.30
                    id_nodo[i].acumulado=id_nodo[i].acumulado-106000000000000000000;
                    //reinversion a los padres
                    asignar_pago(id_nodo[i].ref,58300000000000000000,12720000000000000000,13780000000000000000,5300000000000000000,2120000000000000000,3180000000000000000);
                }
            }
            
        }
    }
    function send_pays(uint amount,address to)private{
        require(address(this).balance >=amount);
        require(to != address(0));
        to.transfer(amount);
    }
    function mirar_arrat(uint a)public view returns(uint){
        return personas_array[a];
    }
    function hay_pagos() public view returns(bool){
    for (uint i = 1; i<=personas_array.length; i++){
        uint level=id_nodo[i].nivel;
        uint acum=id_nodo[i].acumulado;
        
            if(level ==1){
                if(id_nodo[i].pagos==0 &&acum >= 75000000000000000){
                   return true;
                }
                if(id_nodo[i].pagos==1 && acum>=225000000000000000){
                    return true;
                }
                if(id_nodo[i].pagos==2 && acum>=450000000000000000){
                    return true;
                }
            }
            if(level ==2){
                if(id_nodo[i].pagos==0 &&acum >= 150000000000000000){
                  return true;
                }
                if(id_nodo[i].pagos==1 && acum>=450000000000000000){
                     return true;
                }
                if(id_nodo[i].pagos==2 && acum>=900000000000000000){
                     return true;
                }
            }
            if(level ==3){
                if(id_nodo[i].pagos==0 &&acum >= 300000000000000000){
                   return true;
                }
                if(id_nodo[i].pagos==1 && acum>=900000000000000000){
                    return true;
                }
                if(id_nodo[i].pagos==2 && acum>=1800000000000000000){
                  return true;
                }
            }
            if(level ==4){
                if(id_nodo[i].pagos==0 &&acum >= 600000000000000000){
                     return true;
                }
                if(id_nodo[i].pagos==1 && acum>=1800000000000000000){
                    return true;
                }
                if(id_nodo[i].pagos==2 && acum>=3600000000000000000){
                     return true;
                }
            }
            if(level ==5){
                if(id_nodo[i].pagos==0 &&acum >= 1600000000000000000){
                    return true;
                }
                if(id_nodo[i].pagos==1 && acum>=3600000000000000000){
                   return true;
                }
                if(id_nodo[i].pagos==2 && acum>=7200000000000000000){
                   return true;
                }
            }
            if(level ==6){
                if(id_nodo[i].pagos==0 &&acum >= 2500000000000000000){
                     return true;
                }
                if(id_nodo[i].pagos==1 && acum>=6000000000000000000){
                    return true;
                }
                if(id_nodo[i].pagos==2 && acum>=12000000000000000000){
                    return true;
                }
            }
            if(level ==7){
                if(id_nodo[i].pagos==0 &&acum >= 4000000000000000000){
                    return true;
                }
                if(id_nodo[i].pagos==1 && acum>=10500000000000000000){
                     return true;
                }
                if(id_nodo[i].pagos==2 && acum>=21000000000000000000){
                    return true;
                }
            }
            if(level ==8){
                if(id_nodo[i].pagos==0 &&acum >= 6500000000000000000){
                     return true;
                }
                if(id_nodo[i].pagos==1 && acum>=19500000000000000000){
                    return true;
                }
                if(id_nodo[i].pagos==2 && acum>=39000000000000000000){
                   return true;
                }
            }
            if(level ==9){
                if(id_nodo[i].pagos==0 &&acum >= 13000000000000000000){
                    return true;
                }
                if(id_nodo[i].pagos==1 && acum>=39000000000000000000){
                    return true;
                }
                if(id_nodo[i].pagos==2 && acum>=78000000000000000000){
                    return true;
                }
            }
            if(level ==10){
                if(id_nodo[i].pagos==0 &&acum >= 25000000000000000000){
                   return true;
                }
                if(id_nodo[i].pagos==1 && acum>=78000000000000000000){
                  return true;
                }
                if(id_nodo[i].pagos==2 && acum>=156000000000000000000){
                  return true;
                }
            }
            if(level ==11){
                if(id_nodo[i].pagos==0 &&acum >= 106000000000000000000){
                     return true;
                }
                if(id_nodo[i].pagos==1 && acum>=159000000000000000000){
                    return true;
                }
                if(id_nodo[i].pagos==2 && acum>=318000000000000000000){
                     return true;
                }
            }
           
        }
         return false;
    }
    function pago(uint amount,address to)public isowner{
        require(address(this).balance >=amount);
        require(to != address(0));
        to.transfer(amount);
    }
    modifier isowner(){
        require(msg.sender==owner);
        _;
    }
    
    
  
    

}