// ..........................................................................
// ..........................................................................
// ..........................................................................
// ..........................................................................
// ..........................*&&&&&,........&&&&&&...........................
// .....................,(....&&&&&(.......&&*..,&&..........................
// .................,&&/.&&....&&&&#.........&&&&&...,&&&&&&.................
// ...................&&&.........................../&#&&&&..................
// ....................#&............***.***.............&&....,.............
// ...........&&&&&&&&...............***.***................*&&&*&&..........
// ............&&&&..........................................&&...&&.........
// .............&&.......&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%......,&&&&..........
// ....................&&&&&.....,*#&&&&&&&&&#*,.....&&&&%...................
// ....................&&&............&&&&&...........,&&&...................
// ...................&&&&............,&&&,............&&&&..................
// ...................&&&&%........*%&&&&&&&#*........&&&&&..................
// ...................&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&..................
// ..............,......&&&&&&&&%&&&&&&...&&&&&&%&&&&&&&&......*.............
// ...............*.............&&&&&.......&&&&&............**..............
// ...............,**..........&&&&%....&....&&&&&.........***...............
// ................****........&&&&&&&&&&&&&&&&&&&.......****................
// ...............*******.......&&&&&&&&&&&&&&&&&......,******...............
// .................****.......&&&&&&,(&&&&*&&&&&&......****.................
// ..................****..............................****..................
// ..................******.....&&&.*&&&&&&&.,&&&....******..................
// .....................**.......&&&&&&&&&&&&&&&......**.....................
// .......................**......&&&&&&&&&&&&&.....**.......................
// ..................................#&&&&&(.................................
// ..........................................................................
// ....................................***...................................
// ..........................................................................
// ..........................................................................

/*


 ██▀███  ▓█████  ███▄ ▄███▓ ██▓▒██   ██▒    ██░ ██  ▄▄▄       ██▓     ██▓     ▒█████   █     █░▓█████ ▓█████  ███▄    █
▓██ ▒ ██▒▓█   ▀ ▓██▒▀█▀ ██▒▓██▒▒▒ █ █ ▒░   ▓██░ ██▒▒████▄    ▓██▒    ▓██▒    ▒██▒  ██▒▓█░ █ ░█░▓█   ▀ ▓█   ▀  ██ ▀█   █
▓██ ░▄█ ▒▒███   ▓██    ▓██░▒██▒░░  █   ░   ▒██▀▀██░▒██  ▀█▄  ▒██░    ▒██░    ▒██░  ██▒▒█░ █ ░█ ▒███   ▒███   ▓██  ▀█ ██▒
▒██▀▀█▄  ▒▓█  ▄ ▒██    ▒██ ░██░ ░ █ █ ▒    ░▓█ ░██ ░██▄▄▄▄██ ▒██░    ▒██░    ▒██   ██░░█░ █ ░█ ▒▓█  ▄ ▒▓█  ▄ ▓██▒  ▐▌██▒
░██▓ ▒██▒░▒████▒▒██▒   ░██▒░██░▒██▒ ▒██▒   ░▓█▒░██▓ ▓█   ▓██▒░██████▒░██████▒░ ████▓▒░░░██▒██▓ ░▒████▒░▒████▒▒██░   ▓██░
░ ▒▓ ░▒▓░░░ ▒░ ░░ ▒░   ░  ░░▓  ▒▒ ░ ░▓ ░    ▒ ░░▒░▒ ▒▒   ▓▒█░░ ▒░▓  ░░ ▒░▓  ░░ ▒░▒░▒░ ░ ▓░▒ ▒  ░░ ▒░ ░░░ ▒░ ░░ ▒░   ▒ ▒
  ░▒ ░ ▒░ ░ ░  ░░  ░      ░ ▒ ░░░   ░▒ ░    ▒ ░▒░ ░  ▒   ▒▒ ░░ ░ ▒  ░░ ░ ▒  ░  ░ ▒ ▒░   ▒ ░ ░   ░ ░  ░ ░ ░  ░░ ░░   ░ ▒░
  ░░   ░    ░   ░      ░    ▒ ░ ░    ░      ░  ░░ ░  ░   ▒     ░ ░     ░ ░   ░ ░ ░ ▒    ░   ░     ░      ░      ░   ░ ░
   ░        ░  ░       ░    ░   ░    ░      ░  ░  ░      ░  ░    ░  ░    ░  ░    ░ ░      ░       ░  ░   ░  ░         ░


*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC1155.sol";
import "./ERC1155Supply.sol";
import "./ERC1155Burnable.sol";
import "./IERC20.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract RemixHalloween2021 is ERC1155, ERC1155Burnable, ERC1155Supply, Ownable, Pausable {
    using Strings for uint256;

    uint8 public constant TOKEN_COUNT = 30;

    // account => {tokenId => claimed}
    mapping(address => mapping(uint256 => bool)) public claimedTokens;

    bytes32 public currentMerkleRoot;
    string public baseURI;

    address payable internal immutable PAYOUT_ADDRESS;

    constructor(
        string memory _baseURI,
        bytes32 _merkleRoot,
        address _payoutAddress
    ) ERC1155(_baseURI) {
        baseURI = _baseURI;
        currentMerkleRoot = _merkleRoot;
        PAYOUT_ADDRESS = payable(_payoutAddress);
        // Start paused
        pauseSale();
    }

    function uri(uint256 _tokenId) public view override returns (string memory) {
        require(_tokenId != 0 && _tokenId <= TOKEN_COUNT, "Invalid token");
        return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, _tokenId.toString()))
        : baseURI;
    }

    /* Minting */

    function mintPublic(
        uint256[] memory _tokenIds,
        uint256[] memory _quantities,
        bytes32[] calldata _proof
    ) public payable whenNotPaused {
        require(_tokenIds.length == _quantities.length, "Invalid input");
        require(verify(leaf(msg.sender, _tokenIds, _quantities), _proof), "Invalid merkle proof");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            mintInternal(msg.sender, _tokenIds[i], _quantities[i]);
        }
    }

    function mintOwner(address _to, uint256 _tokenId, uint256 _quantity) public onlyOwner {
        mintInternal(_to, _tokenId, _quantity);
    }

    function mintInternal(address _account, uint256 _tokenId, uint256 _quantity) internal {
        require(totalSupply(_tokenId) + _quantity <= supplyForToken(_tokenId), "Not enough left");

        require(claimedTokens[_account][_tokenId] == false, "Account already claimed this token");
        claimedTokens[_account][_tokenId] = true;

        _mint(_account, _tokenId, _quantity, "");
    }

    /* Merkle Tree Helper Functions */

    function leaf(
        address _account,
        uint256[] memory _tokenIds,
        uint256[] memory _quantities
    ) public pure returns (bytes32) {
        bytes memory concatResult = abi.encodePacked(_account);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            concatResult = abi.encodePacked(concatResult, ',', _tokenIds[i], ',', _quantities[i]);
        }
        return keccak256(concatResult);
    }

    function verify(bytes32 _leaf, bytes32[] memory _proof) internal view returns (bool) {
        return MerkleProof.verify(_proof, currentMerkleRoot, _leaf);
    }

    /* Owner Functions */

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        currentMerkleRoot = _merkleRoot;
    }

    function pauseSale() public onlyOwner {
        _pause();
    }

    function unpauseSale() public onlyOwner {
        _unpause();
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function withdraw() public onlyOwner {
        Address.sendValue(PAYOUT_ADDRESS, address(this).balance);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        require(address(token) != address(0));
        token.transfer(_msgSender(), token.balanceOf(address(this)));
    }

    receive() external payable {}

    /* Helpers */
    function supplyForToken(uint256 _tokenId) pure public returns (uint256) {
        require(_tokenId != 0 && _tokenId <= TOKEN_COUNT, "Invalid token");

        // 1-5: 5 editions with supply of 10 (total 50)
        // 6-30: 25 editions with supply of 20 (total 500)
        if (_tokenId < 6) {
            return 10;
        } else {
            return 20;
        }
    }

    /* Overrides */

    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal override(ERC1155, ERC1155Supply) {
        super._mint(account, id, amount, data);
    }

    function _mintBatch(address account, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC1155, ERC1155Supply) {
        super._mintBatch(account, ids, amounts, data);
    }

    function _burn(address account, uint256 id, uint256 amount) internal override(ERC1155, ERC1155Supply) {
        super._burn(account, id, amount);
    }

    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal override(ERC1155, ERC1155Supply) {
        super._burnBatch(account, ids, amounts);
    }
}

/* Contract by:

          _       _ _
    ____ | |     | | |
   / __ \| | ___ | | |_ __ _ _ __   ___  ___
  / / _` | |/ _ \| | __/ _` | '_ \ / _ \/ __|
 | | (_| | | (_) | | || (_| | |_) |  __/\__ \
  \ \__,_|_|\___/|_|\__\__,_| .__/ \___||___/
   \____/                   | |
                            |_|

                _            _       _             _
   ____        | |          (_)     | |           | |
  / __ \   ___ | |__   _ __  _  ___ | |__    ___  | |
 / / _` | / __|| '_ \ | '__|| |/ __|| '_ \  / _ \ | |
| | (_| || (__ | | | || |   | |\__ \| | | || (_) || |
 \ \__,_| \___||_| |_||_|   |_||___/|_| |_| \___/ |_|
  \____/

*/
