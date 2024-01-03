pragma solidity ^0.6.0;


// 
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// 
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNNWMWXKNMMMMNNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXXNXKNWkdKN0xKWkl0MMMWkdXMMMMMWKKNNNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOKWWxoKXXWMOl0MWdlXOl0MMWXOlxWMMMNxoKWWK0WNKKNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX0KWMXllXMKld0KWMKlkMWkdXOlOWXXXNkl0MMMOcOMMMWW0oxXWKkKMWNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXdlxXN0odKKolkkOOOloKKOKNOdO0kOXNKdxXNXkldOOkOOloXWMKlkM0oOXXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMN0xdxkdcllcccccccccodkO0KKKKKK0K0OxdolccclllllcloxkooX0ldXkoKMNXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxxNMMMMMMMX0xccccccccccccccccccldO0KKKK0Odl:clodddddddddddoccdxlx0xx0WNxdKXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNMMWKodXMMNXWNOocccc:;;;;;;;;;::cccccldO0KOdc:coddolllcccllllodddl:lKkoKMKooKKokMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxxOXWNdo0XOk0dlc:;,'''.''.....'',;:ccccoxxo::lddlcccccccccccccclodocldxKklxXXOkOkOKXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMWXNMMWKkxdxxOxx00Odc:;''............,''.',;:cc::::ldoccccc::;;::::::c:clddclk0kkNWMNklxXWN00WMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMWWXXNWMNKNWKxk0KK0xc;'.',c,..,.     .cOko:,',;c::;:odloxOOo;cc,',,,,;loccldo:o0KKKXN0o0MMW0lkWWNWMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMW0xxkkxdkXK0KKKKKKK0o,'';d0K: 'o,.cxc. ;XMWXx:'';;;,:dxOKNN0c;od:cxxl,,dK0dldo;lOKKK0K0OKX0xokX0dxKNMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMWWWNK000OkxO00KKKKKKKOl'.,dXWWo. ,'.lOo. lXXOo:'..'''':dooxOK0o,:l:lkOl,;kXXKxdo,ckK00KKK00OO0KOdokKkkNMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMWNKOkxOXNXKXXKKK0KKKK0Oxl;,',:lxd;.    .. .cc;''..'',,,';odcccldo:;;,,;;,;okkdloxdclkOOO0KKKKKK0dd0OxOx0WMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMK0WWN0ddXX00K0KKKKK0Odlccc:;,'..''.............''',,,,,,,cdoccccccc::::::cccccldkkxxkxxk0KKKKKK00KOoOWMWWNXXWMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMM0dkNMMWOOKKKKKKKK0Odlcccccccc:;,''.........'''',,,,,,,,,,,codlcccccccccccccclodocccccc:cdO0KKKKKKKkx0XNXKdoKWMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMKxOXKxdkO000KKKKKKK0xlccccccccccccc:;;,,,,,,,;;;;,,,,,,,,,,,,,;lodollccccccclodddl:::::::;::lx0KKKKKK000NW0odXWNKXMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMWXKOxxxk0K00KKKKKKKKOdlcccccccccccccccccccccccc:;;,,,,,,,,,,,,,,,,;clodddddddddooc::::;::;:::::cd0KKKKKKKKKkokNMWXkxKMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWKOKWMWKkdk0KKKKKKKKOdcccccccccccccccccccccccc:;;,,,,,,,,,,,,,,,,,,,,,,;:clllcc::;:::;:::;::;::;::d0KKKKKKKKO0XXOxxxkOXMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMWXkxxkKNWWX0KKKKKKKK0xlcccccccccccccccccccccc:;;,,,,,,,,,,,,,,,,,,,,,,,,,,,;;:::::::::::::;::;::::;cx0KKKKKKKK0xdx0NWWKKNMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMN0KNKkxdxOKKKKKKKKKKkoccccccccccccccc:::::cc:;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;;::::::::::::::::::::::lkKKKKKKKKK0KWMWXOkdkNMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMWWNWWWNKO0KKKKKKKKK0xlcccccccccc::::::::::::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::::::::::::::::::::::::x00KK0KK0KKKOxxxkOKNWMMMMMMMMMMMMMM
// MMMMMMMMMMMMMNOxkxxkxk0KKKKKKKKKK0dcccccccccc::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;:d0KKKKKKKKKKO0X0xxxO0XWMMMMMMMMMMMM
// MMMMMMMMMMMMMWNXKKXWX0KKKKKKKKKKK0dcccccccccc::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::d0KKKKK0KKKKKKOxOXWWNKXMMMMMMMMMMMM
// MMMMMMMMMMMNXNWMWNX00KKKKKKKKKKKK0xlccccccccc:::::::;;,,,,;;;;;;;;::::::::::::::::::;;;;;;;;,,,,;:::::::::::::::::cx0KKKKKKKKKKK00KNWNKkxKMMMMMMMMMMMM
// MMMMMMMMMMMNXNXKkkOO0KKKKKKKKKKKKKOoccccccccc::::::::;;;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;;;;:::::::::::::::::lOKKKKKKKKKKKKK00OkxxkXWWMMMMMMMMMMM
// MMMMMMMMMMW0kxxxxO0KKKKKKKKKKKKKKK0xlcccccccccc:::::::::::::;;;;;;;,,,,,,,,,,,,,,,,,;;;;;;;::::::::::::::::::::::cx0KKKKKKKKKKKKKKKXXNNNKxOWMMMMMMMMMM
// MMMMMMMMMMXkxOKNNXKKKKKKKKKKKKKKKKK0xlccccccccccc:::::::::::::::::::::::::::::::::::::::::::::::::::::::::;:::::cd0KKKKKKKKKKKKKKK00NNKxoxXMMMMMMMMMMM
// MMMMMMMMMMWNNWWWN0O0KKKKKKKKKKKKKKKK0xlccccccccccccc:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::cx0KKKKKKKKKKKKKKKKKXKxldKNKXMMMMMMMMMM
// MMMMMMMMMWKkxkOkxkOKKKKKKKKKKKKKKKKKK0koccccccccccccccccc:::::::::::::::::::::::::::::::::::::::::::::::::;:::lk0KKKKKKKKKKKKKKKKKKKOkKNNNNNMMMMMMMMMM
// MMMMMMMMMXkk0xdkO00KKKKKKKKKKKKKKKKKKK00xlccccccccccccccccccccccccccccccc::::::::::::::::::;::::::::::::::::lxOKKKKKKKKKKKKKKKKKK0K0OXMMMMMMMMMMMMMMMM
// MMMMMMMMMNOkkxxkxx0KKKKKKKKKKKKKKKKKKKKK0Oxolccccccccccccccccccccccccccccc::::::::::::::;;:::::;;;:::::;::lxO0KKKKKKKKKKKKKKKKKKKKKKXWMMMMMMMMMMMMMMMM
// MMMMMMMMMNXNMMMN0O0KKKKKKKKKKKKKKKKKKKKKKK0Okdlccccccccccccccccccccccccccc:::::::::::::::::::::;;::::::coxO0KKKKKKKKKKKKKKKKKKKKKKKKNMMMMMMMMMMMMMMMMM
// MMMMMMMMMXKNNKKWKO0KKKKKKKKKKKKKKKKKKKKKKKKK0kl,,;cccccccccccccccccccccccc:::::::::::::::::::::;;;;;,',oO0K0KKKKKKKKKKKKKKKKKKKKKKKKKOxxxk0NMMMMMMMMMM
// MMMMMMMMMXkxxddkxx0KKKKKKKKKKKKKKKKKKKKKK0Od:.    .lxolccccccccccccccccccc:::::::::::::::::::;:clo:.    .:dO0KKKKKKKKKKKKKKKKKKKKKK0O0KXX0OKWMMMMMMMMM
// MMMMMMMMMNK0KXNNNKKKKKKKKKKKKKKKKKKKKK0Odl:.       'ONKOdlcccccccccccccccc:::;:::::;;::;:;;:cdOKXx.       .,cdk0KKKKKKKKKKKKKKKKKK00KXWMMWNXWMMMMMMMMM
// MMMMMMMMMWKKNNNXKOOKKKKKKKKKKKKKKKK0kdc;,,'.        'OWMWKkl:::::::ccccccc:::;::::;;;:;;;:lkKWMWx.         ...,:ok00KK0KKKKKKKKKKK0OkKNMMNKXMMMMMMMMMM
// MMMMMMMMMW0xkkkkxxOKKKKKKKKKKKK0Oxoc;,,,,,'          'OWMMWXOdc;;;;;::::::;;;;;;;;;;;;;cd0NWMMWx.          ......';lxO0KKKKKKK0KKKK0KXXNWMMMMMMMMMMMMM
// MMMMMMMMMMKOKNMMMWNKKKKKKKKK0kdl:,,,,,,,,,.           'OWMMMMWKxl:;;;;;;;;;;;;;;;;;;:okKWMMMMWx.           .........',cdk0KKKKKKKK0KX0kxxkXMMMMMMMMMMM
// MMMMMMMMMMWKKNNN0kOKK0KK00kdc;,,,,,,,,,,,,.            'kWMMMMMWNOdc;;;;;;;;;;;;;;cd0NWMMMMMWx.            .............,:ok0KKKKKkxxxkkO0NMMMMMMMMMMM
// MMMMMMMMMMMXKNKxlkXNK0Oxoc;,,,,,,,,,,,,,,'.             'kWMMMMMMMWKkl:;;;;;;;;:okKWMMMMMMMWx.             ................';lxO0OddO0XWMMMMMMMMMMMMMM
// MMMMMMMMMMMMNOodKNN0xl:,,,,,,,,,,,,,,,,,,,'...           .kWMMMMMMMMWN0dc;;;:lx0NMMMMMMMMMWx.             ....................';lk0Oxdxxx0WMMMMMMMMMMM
// MMMMMMMMMMMMKdONNNNXo,,,,,,,,,,,,,,,,,,,,,,,,''...        .kWMMMMMMMMMMWKxookXWMMMMMMMMMMWd.         ...........................'lkkkkO0OXMMMMMMMMMMMM
// MMMMMMMMMMMMWNNXOkxxdc;,,,,,,,,,,,,,,,,,,,,,,'...          .kWMMMMMMMMMN0occo0NMMMMMMMMMWd.           .........................'dNWWW0xOXMMMMMMMMMMMMM
// MMMMMMMMMMMMMNkdkOKNMNd;,,,,,,,,,,,,,,,,,,,,'.              .kWMMMMMWXOo:;,'';lONMMMMMMNd.              .......................,oOKNMNKXMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMWWMMMMMWx;,,,,,,,,,,,,,,,,,,,,,'..             .kWMMMWXxc;;;,'''':xXWMMMNd.              ......................'o00kxxxkOXMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMWKK0xdko,,,,,,,,,,,,,,,,,,,,,,'..            .xWWXKK0ko:;,',:ok0KKNWNd.             ........................,kWMMWXkxKMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMWOdkOkkxl:;,,,,,,,,,,,,,,,,,,,,,,''.           .d0KKKKKOo;,',oOKKKKK0l.           .........................'lxxdxOXXKXMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMX0kxdxOKOl,,,,,,,,,,,,,,,,,,,,,,,,,'.          .l0KK0Oo:;,'';oOKKKOc.          ....,,....................,l0WXkxxdkNMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMKk0NWMNXKx;',,,,,,,,,,,,,,,,,,,,,,,,'..        .l00kl;;;,''',lkKOc.         ...'ckXKd;.................'cOXWWXXXKXWMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMXKNNOkxdoo:,,,,,,,,,,,,,,,,,,,,,,,,,'..       .lkdlllllccc:,cdc.        ...,lONMMMWXxokOo,.........'lOkdokXWNKNMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMNXKkddkKKOxc,,,,,,,,,,,,,,,,,,,,,,,,,,''.      .cxxxxxxxxdl,'.       ....,o0NWWWWWWWWWWMWKd;.....,ldxkkO0xdkNMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMWKkKN0odOXKd,',,,,,,,,,,,,,,,,,,,,,,,,,,'.      ';:::;,,,,'.      ......;loooooooooooooool:'...:OWMMWKxx0KXWMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMKdOWMXkodxl;,,,,,,,,,,,,,,,,,,,,,,,,,,'..    .,;;,,'''.     .........'''''''''''''''''..,cllkNMMMMNKXWMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMNKXKxoxXWKodd:,,,,,,,,,,,,,,,,,,,',,,,,,'..   .,;,'''.    ............................,cok00xokNMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMWXkxXWNXxc0WOl;,,,,,,,,,,,,,,,,,,,,,,,,,,,'.  .,,''.  ............................',cONXkodXKddXMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKXNdoXNXXd:lc;,,,,,,,,,,,,,,,,,,,,,,,,,'...'.. ...........................';ck0ddXMMXdkWWNWMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNWNooKNWXldNNxc;,,,,,,,,,,,,,,,,,,,,,,,,,''............................';ckXNXNNXXNWNKXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0OWMMOlkXXNXd:dd:,,,,,,,,,,,,,,,,,,,,,,,'.......................,cook0xdxkO0XWNKKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWkxXWWMMOlOXOkdll:,,,,,,,,,,,,,,,,,,'...................,ll;lKWKXWWK0Okdd0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMWNN0cxWMWXXXd:doll:,,,,,,,,,,,,'..........,;;';dkkclXMXxodOXWMWKKWWNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXKNXodWMWX0klkNNNWxckd:d0Oooxkocclocoxdxkol0NdlXMMKlxWMWXkokWMMWNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW00WXKNKodNMMMNodWXldXXXWMMOllxNXXWXNMXoxWKlkWWWOlOK0WMNXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNN0xKMMMMOlOMMklOXWMMMN0xdoxXWXNMWdoXWdlKX0KO0XXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0kNMMXxOWMMMMNKKXKdOWKKWMOdKWXOXWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMWNXNNXWMNNWMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// https://Newspaper.finance
contract Referrers is Ownable {

    mapping(address => bool) private referrers;

    constructor()
    public
    Ownable()
    {
    }

    function addReferrers(address[] memory addresses) public onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            referrers[addresses[i]] = true;
        }
    }

    function removeReferrers(address[] memory addresses) public onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            referrers[addresses[i]] = false;
        }
    }

    function isReferrer(address _address) external view returns (bool) {
        return referrers[_address];
    }
}