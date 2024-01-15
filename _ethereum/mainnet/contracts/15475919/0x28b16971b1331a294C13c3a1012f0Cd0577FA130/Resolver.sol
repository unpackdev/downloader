//SPDX-License-Identifier: WTFPL v6.9
pragma solidity >0.8.0 <0.9.0;

import "./Interface.sol";
import "./Util.sol";

/**
 * @dev : BENSYC Resolver Base
 */
 
abstract contract ResolverBase {
    /// @dev : Modifier to allow only dev
    modifier onlyDev() {
        if (msg.sender != BENSYC.Dev()) {
            revert OnlyDev(BENSYC.Dev(), msg.sender);
        }
        _;
    }

    /// @dev : ENS Contract Interface
    iENS public ENS;

    /// @dev : BENSYC Contract Interface
    iBENSYC public BENSYC;

    mapping(bytes4 => bool) public supportsInterface;

    modifier isValidToken(uint256 id) {
        if (id >= BENSYC.totalSupply()) {
            revert InvalidTokenID(id);
        }
        _;
    }

    /**
     * @dev : setInterface
     * @param sig : signature
     * @param value : boolean
     */
    function setInterface(bytes4 sig, bool value) external payable onlyDev {
        require(sig != 0xffffffff, "INVALID_INTERFACE_SELECTOR");
        supportsInterface[sig] = value;
    }

    /**
     * @dev : withdraw ether only to Dev (or multi-sig)
     */
    function withdrawEther() external payable {
        (bool ok,) = BENSYC.Dev().call{value: address(this).balance}("");
        require(ok, "ETH_TRANSFER_FAILED");
    }

    /**
     * @dev : to be used in case some tokens get locked in the contract
     * @param token : token to release
     * @param bal : token balance to withdraw
     */
    function withdrawToken(address token, uint256 bal) external payable {
        iERC20(token).transferFrom(address(this), BENSYC.Dev(), bal);
    }

    // @dev : Revert on fallback
    fallback() external payable {
        revert();
    }

    /// @dev : Revert on receive
    receive() external payable {
        revert();
    }

    error Unauthorized(address operator, address owner, uint256 id);
    error NotSubdomainOwner(address owner, address from, uint256 id);
    error OnlyDev(address _dev, address _you);
    error InvalidTokenID(uint256 id);
}

/**
 * @title BENSYC Resolver
 */

contract Resolver is ResolverBase {
    using Util for uint256;
    using Util for bytes;

    /// @notice : encoder: https://gist.github.com/sshmatrix/6ed02d73e439a5773c5a2aa7bd0f90f9
    /// @dev : default contenthash (encoded from IPNS hash)
    //  IPNS : k51qzi5uqu5dkco782zzu13xwmoz6yijezzk326uo0097cr8tits04eryrf5n3
    function DefaultContenthash() external view returns (bytes memory) {
        return _contenthash[bytes32(0)];
    }

    constructor(address _bensyc) {
        BENSYC = iBENSYC(_bensyc);
        ENS = iENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
        supportsInterface[iResolver.addr.selector] = true;
        supportsInterface[iResolver.contenthash.selector] = true;
        supportsInterface[iResolver.pubkey.selector] = true;
        supportsInterface[iResolver.text.selector] = true;
        supportsInterface[iResolver.name.selector] = true;
        supportsInterface[iOverloadResolver.addr.selector] = true;

        _contenthash[bytes32(0)] =
            hex"e5010172002408011220a7448dcfc00e746c22e238de5c1e3b6fb97bae0949e47741b4e0ae8e929abd4f";
    }

    /**
     * @dev : sets default contenthash
     * @param _content : default contenthash to set
     */
    function setDefaultContenthash(bytes memory _content) external onlyDev {
        _contenthash[bytes32(0)] = _content;
    }

    /**
     * @dev : verify ownership of subdomain
     * @param node : subdomain
     */
    modifier onlyOwner(bytes32 node) {
        require(msg.sender == ENS.owner(node), "Resolver: NOT_AUTHORISED");
        _;
    }

    mapping(bytes32 => bytes) internal _contenthash;

    /**
     * @dev : return default contenhash if no contenthash set
     * @param node : subdomain
     */
    function contenthash(bytes32 node) public view returns (bytes memory _hash) {
        _hash = _contenthash[node];
        if (_hash.length == 0) {
            _hash = _contenthash[bytes32(0)];
        }
    }

    event ContenthashChanged(bytes32 indexed node, bytes _contenthash);

    /**
     * @dev : change contenthash of subdomain
     * @param node: subdomain
     * @param _hash: new contenthash
     */
    function setContenthash(bytes32 node, bytes memory _hash) external onlyOwner(node) {
        _contenthash[node] = _hash;
        emit ContenthashChanged(node, _hash);
    }

    mapping(bytes32 => mapping(uint256 => bytes)) internal _addrs;

    event AddressChanged(bytes32 indexed node, address addr);

    /**
     * @dev : change address of subdomain
     * @param node : subdomain
     * @param _addr : new address
     */
    function setAddress(bytes32 node, address _addr) external onlyOwner(node) {
        _addrs[node][60] = abi.encodePacked(_addr);
        emit AddressChanged(node, _addr);
    }

    event AddressChangedForCoin(bytes32 indexed node, uint256 coinType, bytes newAddress);

    /**
     * @dev : change address of subdomain for <coin>
     * @param node : subdomain
     * @param coinType : <coin>
     */
    function setAddress(bytes32 node, uint256 coinType, bytes memory _addr) external onlyOwner(node) {
        _addrs[node][coinType] = _addr;
        emit AddressChangedForCoin(node, coinType, _addr);
    }

    /**
     * @dev : default subdomain to owner if no address is set for Ethereum [60]
     * @param node : sundomain
     * @return : resolved address
     */
    function addr(bytes32 node) external view returns (address payable) {
        bytes memory _addr = _addrs[node][60];
        if (_addr.length == 0) {
            return payable(ENS.owner(node));
        }
        return payable(address(uint160(uint256(bytes32(_addr)))));
    }

    /**
     * @dev : resolve subdomain addresses for <coin>; if no ethereum address [60] is set, resolve to owner
     * @param node : sundomain
     * @param coinType : <coin>
     * @return _addr : resolved address
     */
    function addr(bytes32 node, uint256 coinType) external view returns (bytes memory _addr) {
        _addr = _addrs[node][coinType];
        if (_addr.length == 0 && coinType == 60) {
            _addr = abi.encodePacked(ENS.owner(node));
        }
    }

    struct PublicKey {
        bytes32 x;
        bytes32 y;
    }

    mapping(bytes32 => PublicKey) public pubkey;

    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);

    /**
     * @dev : change public key record
     * @param node : subdomain
     * @param x : x-coordinate on elliptic curve
     * @param y : y-coordinate on elliptic curve
     */
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) external onlyOwner(node) {
        pubkey[node] = PublicKey(x, y);
        emit PubkeyChanged(node, x, y);
    }

    mapping(bytes32 => mapping(string => string)) internal _text;

    event TextRecordChanged(bytes32 indexed node, string indexed key, string value);

    /**
     * @dev : change text record
     * @param node : subdomain
     * @param key : key to change
     * @param value : value to set
     */
    function setText(bytes32 node, string calldata key, string calldata value) external onlyOwner(node) {
        _text[node][key] = value;
        emit TextRecordChanged(node, key, value);
    }

    /**
     * @dev : set default text record <onlyDev>
     * @param key : key to change
     * @param value : value to set
     */
    function setDefaultText(string calldata key, string calldata value) external onlyDev {
        _text[bytes32(0)][key] = value;
        emit TextRecordChanged(bytes32(0), key, value);
    }

    /**
     * @dev : get text records
     * @param node : subdomain
     * @param key : key to query
     * @return value : value
     */
    function text(bytes32 node, string calldata key) external view returns (string memory value) {
        value = _text[node][key];
        if (bytes(value).length == 0) {
            if (bytes32(bytes(key)) == bytes32(bytes("avatar"))) {
                return string.concat(
                    "eip155:",
                    block.chainid.toString(),
                    "/erc721:",
                    abi.encodePacked(address(BENSYC)).toHexString(),
                    "/",
                    BENSYC.Namehash2ID(node).toString()
                );
            } else {
                return _text[bytes32(0)][key];
            }
        }
    }

    event NameChanged(bytes32 indexed node, string name);

    /**
     * @dev : change name record
     * @param node : subdomain
     * @param _name : new name
     */
    function setName(bytes32 node, string calldata _name) external onlyOwner(node) {
        _text[node]["name"] = _name;
        emit NameChanged(node, _name);
    }

    /**
     * @dev : get default name at mint
     * @param node : subdomain
     * @return _name : default name
     */
    function name(bytes32 node) external view returns (string memory _name) {
        _name = _text[node]["name"];
        if (bytes(_name).length == 0) {
            return string.concat(BENSYC.Namehash2ID(node).toString(), ".boredensyachtclub.eth");
        }
    }
}
