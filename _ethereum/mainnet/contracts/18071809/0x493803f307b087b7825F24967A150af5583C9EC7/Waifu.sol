// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// REI
// FROM BELONGING DATA SYSTEMS MANAGEMENT CORPORATION
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo...''''..'''',,,,,,,,;;:ccllllc:;;;::;;;;;;;::::::;::;;::;,,,,,',,,'',,'''...;0MMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0;...''....'''',,,,,,,,;;;:cllllc;;clc::::ccllllollc:c:,,;;,;,,,,'',,''''','....oNMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx'..''....''''',''',,,,,;;;::c:;;;clc:clooooooooool:;:;,,;;,,,,,,,',,,'''',''...:KMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo...'.....''''''''',,,,,;;;;;;,,;:c:;:coooooooooll:;;;::;;;;,,,,,,'',,,'''','...,kMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:..''....'''''''''',,,,,,;;;,,,;;;;;;:cllllllllc:;;,,:lc;;,,,,,,''''',,'''',''...oWMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO,..'.....'''''''''',,,,,;;;,,,;;,,,;;;::::cc:::;;,,,;lxc,;,,,,,'''''',,,'''','...cXMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk'.''.....''''''''''',,,,;;;,,;,,,;;;;;;;;;;;;;,,,,,;ckx:,,,,,,,''''''',''''''''..:KMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx'.''....''''''''''',,,,,,,,,,,,,;;;;;;;;;;;;;;;,,,;:xKd;,,,,,,'''''.'''''''''''..,kMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd''''....'''''''''',,,,,,,,,,,,;;;;;;;;;;;;;;;;;;:;;oKKo,,,,,,'''''..'''''''''''..'oNMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo.''''..'''''''''',,,,,,,,,,,,,,,;;;;;;;;;;;;;:c:;;lkKkc,,,,,,'''''.''''''''''''.'.cXMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl.''''..''''''''',,,,,,,,,,,,;;;;;;;:::::::::llc::oxOkl;,,,,,,,,'''.'''''''''','''':0MMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl'''''.'''''''''',,,,,;;;,,;;;;:::::::::::coddcclkKNNOc;;;;,,:c;,''.'''''''''','''.,OMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl''''..''''''',,,,,,;;;;;;;;;;::::cc:::clokkdlokKNWN0o:;;;;:oko;,'','''''''''','''..xWMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo''''..'''''',,,,,;;;;;:::;;;:coooollodk0K0kk0XNNWN0dloolldOKkcc:;cc;,,''''''','''..oNMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx,'''..'''''',,,,,;;;;,;c;',cdkO0OkO0XNWWNNNNWWWWNX0kO00OO00koodoxkl;,,,'''''',''',,oNMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk,'''..''''',,,,,,,''.......',cdkOXNNNWWWWWWWWWWNNNX0xl:;,,,''''';::;,,,''',,,,''';coXMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk,''''.'''',,,,,,,,,,,'..';,'..;co0NNWWWWWWWWWWWWWN0d;...','.,;:;,..',''''',,,,''':loKMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO;'''''''',,,,;;;;;:loc;:c:;:::xKKKXNWWWWWWWWWWWWWXK0o;:;;c:;:xKKx:,;;,''',,,,,,,'colKMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO;'''''''',,,,;;;;:lkK0ddxxxkdd0NNNWWWWWWWWWWWWWWWNNNOodxdxxodKNX0o::c;''',,,,,,,'col0MMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0;.''''',,,,,,;;;;lkKKK0kO00000XNNNNNWWWWWWWWWWWWWNNNKOO00Okk0XKKkc:dkc''',,,,,'''cocOMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0:.''''',,,,,,,;:lx0XXXXXXXXXNNNNNNNNNWWWWWWWWWWWWNNNNNNXXXXXXXXOook0x;''',,,,,'''ld:OMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:.'''',,,,,,,';d000XXXXXXXXNNNNNNNNNNWWWWWWWWWWWWNNNNNNXXXXXXX0kkK0o;'''',,,,,'''ox:OMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc.'',,,,,,,''..:kK0KXXXXNNNNNNNNNNNNWWWWWWWWWWWWWNNNNNNNXXNNXXKO0O:''','',,,,,'''ox:OMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMW0c'',,,,,,'''''..,ok0XNNNNNNNNNNNNNWWWWWWWWNWWWWWWNNNNNNNNNNNNX0kd,..''''',,,,''''dk:OMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMNKNWMMMMMMMMMNNWMMMMMWXOo;,,',,''..''''....;lONNNNNNNNNNNWWWWWWWWWNNWWWWWWWWNNNNNNNNNNKo;....''''',,,,'','ox:OMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMM0ONMMMMMMMMMNO0MMMMNKOdc;,,,,''....''''..,;:cxKNNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNWNNNXx;'....''''.',,,'',':l:OMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMNKXWMMMMMMMMNxxWWX0xoc;,,'''.......''',lkKNWWNKKNNWWWWWWWWWWWWWWWNNNNWWWWWWWWWWWWWWNX0KXX0ko;''''.',,''','',;OMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMWNXKKKXXNNNXxldxoc:;,,:;''.......''':kNMMMNNWWXKXNWWWWWWWWWWWNXKXKKKKXNWWWWWWWWWNXKKNWWWMMWKo,''.',,''','..;OMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMWXKK00OOkxc;;;:ldk00l'.......''';xWMMNXkx0XWNXKXNWWWWWWWWWNNNNNNNNNNWWWWWWWNXKKXNNK0KNWMMXo,'..',''','..,OMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNk:'';clooc,..''''''''';OMMWXO:,dKNMMXxokXNWWWWWWWWWWWWWWWWWWWWNN0xkXWWNKo,l0NWMWx,''.'''.','..'xWMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkoc::c:,'''''''''''',dNMMWX0OKNMMM0:.'ck0KXNWWWWWWWWWWWWWNNKxc,.oNMMWXOdkKNMMNo,''.''''','...:KMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXKXk;''',''''''''':OWMMMWWWMMMNo'..'okxkKNWWWWWWWWWWWNXOo,...;OMMWWNXNWWMM0:''''''''','...'dWMMMMMMMMMMMMMMMMMMM

import "./ERC721A.sol";

contract Waifu is ERC721A {
    uint256 public constant MAX_SUPPLY = 999;

    address Minter;

    string public baseUri;

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }

    function changeOwner(address _owner) external onlyOwner() {
        owner = _owner;
    }

    constructor(address _minter, address _devMint) ERC721A("Wife Material", "WIFE") {
        Minter = _minter;
        owner = payable(msg.sender);
        _mintERC2309(_devMint, 19);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function setBaseUri(string calldata newBaseUri) external onlyOwner() {
        baseUri = newBaseUri;
    }

    function mint(address mintReceiver, uint256 amount) external {
        require(address(msg.sender) == Minter, "Not Minter");
        require(totalSupply() + amount <= MAX_SUPPLY, "Max Minted");

        _mint(mintReceiver, amount);
    }
}
