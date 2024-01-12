// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/// @artist: SiA & DOR
/// @title: SOULS
/// @author: manifold.xyz

import "./ERC721.sol";
import "./AdminControl.sol";

import "./ERC721CollectionBase.sol";

// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNNXXXXKKXXXXNNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0kxdlc:;;,'''....''',;;:cldxk0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOxoc;'...                        ...';cox0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0xl;'..                                      ..':okKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkl;..                                                ..;oOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMWKxc'.                                                        .,lkXWMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMWXkc'..                                                             .,o0NMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMW0o,.                                                                    .:kNMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMNOc....                                                                      .;xXMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMNOc.. .                  ......                    ........                      .;kNMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMW0l...                 ..,:cllllc:,..             ..;cloooooc;'.                     .c0WMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMWXd,..                 .':oddddddddddo:..          .;oddddddddddoc.                     .'dXWMMMMMMMMMMMMM
// MMMMMMMMMMMMMW0:..                  .;oddddddddddddddo;.        .cddddddddddddddl.                      .cKWWMMMMMMMMMMM
// MMMMMMMMMMWWNx,...                 .:dddddddddddddddddo;.      .;dddddddddddddddd;.                      .;OWWMMMMMMMMMM
// MMMMMMMMMWWXd....                  ,oddddddddddddddddddo'      .cddddddddddddddddc.                       .,kWWMMMMMMMMM
// MMMMMMMMWWXl...                   .:dddddddddddddddddddd:.     'lddddddddddddddddl.                        .,kWWWMMMMMMM
// MMMMMMMWWXl....                   .lddddddddddddddddddddl.     ,oddddddddddddddddl.                         .,OWWWMMMMMM
// MMMMMMWWXo....                    .lddddddddddddddddddddo,     ;dddddddddddddddddl.                          .:0WWWMMMMM
// MMMMMWWNx'....                    'ldddddddddddddddddddddl'.  .cdddddddddddddddddl.                           .lXWWMMMMM
// MMMMWWWO;......                   ,oddddddddddddddddddddddoc::lddddddddddddddddddc.                            'kWWWMMMM
// MMMWWWXl.......                  .:ddddddddddddddddddddddddddddddddddddddddddddddl.                            .cKWWWMMM
// MMMWWNk'.......                 .,oddddddddddddddddddddddddddddddddddddddddddddddo;.                            'kNWWWMM
// MMWWWXc........               ..:odddddddddddddddddddddddddddddddddddddddddddddddddl:'.                         .lXWWWMM
// MMWWWO,........              .:oddddddddddddddddooddddddddddddddddddddddddddddddddddddl:.                       .;0WWWWM
// MWWWNd..........           .,ldddddddddddddddolllllloodddddddddddddoooooodddddddddddddddo:.                      'kNWWWW
// WWWWXl...........         .:oddddddddddddddolllllllllllodddddddddollllllloodddddddddddddddo;.                   ..xNWWWW
// WWWNKc..........         .:ddddddddddddddddollllllllllloodddddddollcllllllloddddddddddddddddc.                  ..dNWWWW
// WWWNKc...........       .;dddddddddddddddddollllllllllloodddddddollclllllllodddddddddddddddddc.                  .oXNWWW
// WWNNKc............     .'odddddddddddddddddolllllllllllodddddddddolllllllloddddddddddddddddddd:.                ..dXNWWW
// WWNNKc............     .:dddddddddddddddddddoollllllloodddddddddddooolloooddddddddddddddddddddo'                .'xNNWWW
// WWNNXo...............  .lddddddddddddddddddddddoooooddddddddddddddddddddddddddddddddddddddddddd:.              ..,kNNWWW
// WWNNXd'............... 'ldddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd:.              ..:0NNWWW
// WWNNNO;................'lddddddddddddddddddddddddooolooooddddddoooooooodddddddddddddddddddddddd:.             ...oXNNWWW
// WWNNNKl.................cdddddddddddddddddddddddollllllllloooollllllllllodddddddddddddddddddddd;             ...,kXNNWWW
// WWWNNXk,................;ddddddddddddddddddddddollllclllllllllllllllllllodddddddddddddddddddddl.             ...lKNNNWWW
// WWWNNXKl.................cddddddddddddddddddddddolcllllllllllllllllllllloddddddddddddddddddddo;.            ...;kXNNNWWW
// WWWNNNXO:................'lddddddddddddddddddddddollllllllllllllllllllodddddddddddddddddddddo;.            ....oKXNNWWWW
// WWWWNNXKx,................'ldddddddddddddddddddddddoollllllllllllloooddddddddddddddddddddddo;.            ....c0XXNNWWWM
// MWWWNNNXKo'.................:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddc'             ....:OXXNNWWWWM
// MWWWWNNXX0l'.................,lddddddddddddddddddddddddddddddddddddddddddddddddddddddddoc'.            .....;kXXNNNWWWMM
// MMWWWNNNXX0l'..................,coddddddddddddddddddddddddddddddddddddddddddddddddddol;..             .....;kKXXNNWWWWMM
// MMWWWWNNNXX0o'....................,:lodddxdddddddddddddddddddddddddddddddddddddolc:,..              ......;kKXXNNWWWWMMM
// MMMWWWWNNXXX0o,.......................,;:clllooooooooooooooooooooolllcc:::;;,'...                 .......:kKXXNNNWWWMMMM
// MMMMWWWWNNXXXKx;......................................................                          .......'lOKXXNNNWWWMMMMM
// MMMMMWWWWNNXXXKkc'.............................                                               ........;d0KXXNNNWWWWMMMMM
// MMMMMMWWWWNNXXXK0d;................................                                        .........'lOKKXXNNNWWWWMMMMMM
// MMMMMMMWWWWNNNXXKKOl,..................................                                ............:x0KXXXNNNWWWMMMMMMMM
// MMMMMMMMWWWWNNNXXKK0kc,.....................................                       ..............;oOKKXXNNNWWWWWMMMMMMMM
// MMMMMMMMMWWWWNNNXXXKK0xc,......................................................................;oOKKKXXNNNWWWWMMMMMMMMMM
// MMMMMMMMMMMWWWWNNNXXXKK0kl;.................................................................':dOKKKXXNNNWWWWWMMMMMMMMMMM
// MMMMMMMMMMMMWWWWNNNNXXXKK0Oo:'............................................................,lx0KKKXXXNNNWWWWMMMMMMMMMMMMM
// MMMMMMMMMMMMMWWWWWNNNXXXXKKK0xl;'......................................................,cdO0KKKXXXNNNWWWWWMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMWWWWNNNNXXXKKK0Oxo:,'..............................................';cdk0KKKKXXXNNNWWWWWMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMWWWWWNNNNXXXKKKK00kdl:,'......................................',coxO0KKKKKXXXNNNWWWWWWMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMWWWWWNNNNXXXXKKKKK00kdoc:,'............................,;:loxO00KKKKXXXXNNNNWWWWWMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMWWWWWWNNNNXXXXKKKKKKK00Oxdolc:;;,,,'''''''',,,;:ccloxkO000KKKKKXXXXXNNNNWWWWWMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMWWWWWWNNNNXXXXXKKKKKKK00000OOOkkkxxxxxkkkkOO00000KKKKKKKKXXXXNNNNNWWWWWMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWNNNNNXXXXXXKKKKKKKKKKKKKK0KKKKKKKKKKKKKKKKXXXXXXXNNNNNWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWNNNNNNXXXXXXXKKKKKKKKKKKKKKKKKKKKKXXXXXXXXXNNNNNWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
/**
 * Souls Public Sale Contract
 */
contract SOULSPublicSale is ERC721CollectionBase, AdminControl {

    address private immutable SOULS_ADDRESS;

    constructor(address soulsAddress, address signingAddress) {
        require(!ERC721CollectionBase(soulsAddress).active());
        SOULS_ADDRESS = soulsAddress;
        _initialize(
            10000,
            // 0.12345 eth
            123450000000000000,
            0,
            20,
            0,
            0,
            signingAddress,
            false
        );
        purchaseCount = ERC721CollectionBase(soulsAddress).purchaseCount();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721CollectionBase, AdminControl) returns (bool) {
        return ERC721CollectionBase.supportsInterface(interfaceId) || AdminControl.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Collection-withdraw}.
     */
    function withdraw(address payable recipient, uint256 amount) external override adminRequired {
        _withdraw(recipient, amount);
    }

    /**
     * @dev See {IERC721Collection-setTransferLocked}.
     */
    function setTransferLocked(bool locked) external override adminRequired {
        _setTransferLocked(locked);
    }

    /**
     * @dev See {IERC721Collection-premint}.
     */
    function premint(uint16 amount) external override adminRequired {
        _premint(amount, owner());
    }

    /**
     * @dev See {IERC721Collection-premint}.
     */
    function premint(address[] calldata addresses) external override adminRequired {
        _premint(addresses);
    }

    /**
     * @dev See {IERC721Collection-activate}.
     */
    function activate(uint256 startTime_, uint256 duration, uint256 presaleInterval_, uint256 claimStartTime_, uint256 claimEndTime_) external override adminRequired {
        _activate(startTime_, duration, presaleInterval_, claimStartTime_, claimEndTime_);
    }

    /**
     * @dev See {IERC721Collection-deactivate}.
     */
    function deactivate() external override adminRequired {
        _deactivate();
    }

    /**
     *  @dev See {IERC721Collection-setTokenURIPrefix}.
     */
    function setTokenURIPrefix(string calldata prefix) external override adminRequired {
        _setTokenURIPrefix(prefix);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override (ERC721CollectionBase) returns (uint256) {
        return ERC721CollectionBase(SOULS_ADDRESS).balanceOf(owner);
    }

    function purchase(uint16 amount, bytes32 message, bytes calldata signature, bytes32 nonce) public payable virtual override {
        _validatePurchaseRestrictions();

        require(amount <= purchaseRemaining() && (transactionLimit == 0 || amount <= transactionLimit), "Too many requested");

        // Make sure we are not over purchaseLimit
        _validatePrice(amount);
        _validatePurchaseRequest(message, signature, nonce);
        address[] memory receivers = new address[](amount);
        for (uint i = 0; i < amount;) {
            receivers[i] = msg.sender;
            unchecked {
                i++;
            }
        }
        purchaseCount += amount;
        IERC721Collection(SOULS_ADDRESS).premint(receivers);
    }

    /**
     * @dev mint implementation
     */
    function _mint(address to, uint256) internal override {
        purchaseCount++;
        address[] memory receivers = new address[](1);
        receivers[0] = to;
        IERC721Collection(SOULS_ADDRESS).premint(receivers);
    }
}
