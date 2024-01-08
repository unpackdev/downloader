// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract BirdPass is ERC1155Burnable, ERC1155Supply, Ownable {
    using Strings for string;
    using MerkleProof for bytes32[];

    /**
     * @notice Input data root, Merkle tree root for an array of (address, tokenId) pairs,
     *      available for minting
     */
    bytes32 public root = 0x51305dde7e919e826f68296eea6c520400d1f8b8ddb4b617eaab15c456215f82;

    string public _baseURI = "https://xxxxxxxxxxx/metadata/";
    string public _contractURI = "https://xxxxxxxx";
    address private devWallet;
    uint256 public pricePerPass = 0.08 ether;
    bool public locked; //metadata lock
    uint256 public tokensMinted = 0;
    uint256 public maxSupply = 1000;
    mapping(address => uint256) public listPurchases;

    uint256 public saleStartTime = 1637704800; //24 nov 12:00 UTC

    modifier onlyDev() {
        require(msg.sender == devWallet, "only dev can modify");
        _;
    }

    constructor() ERC1155(_baseURI) {
        devWallet = msg.sender;
    }

    //onlyWhitelists can buy. 3 token per whitelisted address
    function whitelistBuy(
        uint256 qty,
        uint256 tokenId,
        bytes32[] calldata proof
    ) external payable {
        require(listPurchases[msg.sender] + qty <= 3, "max 3 per wallet");
        require(tokensMinted + qty <= maxSupply, "out of stock");
        require(pricePerPass * qty == msg.value, "exact amount needed");
        require(isTokenValid(msg.sender, tokenId, proof), "invalid proof");
        require(block.timestamp >= saleStartTime, "not live");
        listPurchases[msg.sender] += qty;

        for (uint256 i = 0; i < qty; i++) {
            tokensMinted = tokensMinted + 1;
            _mint(msg.sender, 1, 1, "");
        }
    }

    //admin mint
    function adminMint(address to, uint256 qty) external onlyOwner {
        require(tokensMinted + qty <= maxSupply, "out of stock");
        tokensMinted = tokensMinted + qty;
        _mint(to, 1, qty, "");
    }

    function setMerkleRoot(bytes32 _root) external onlyDev {
        root = _root;
    }

    function setBaseURI(string memory newuri) public onlyDev {
        require(!locked, "locked functions");
        _baseURI = newuri;
    }

    function setContractURI(string memory newuri) public onlyDev {
        require(!locked, "locked functions");
        _contractURI = newuri;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseURI, uint2str(tokenId)));
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function isTokenValid(
        address _to,
        uint256 _tokenId,
        bytes32[] memory _proof
    ) public view returns (bool) {
        // construct Merkle tree leaf from the inputs supplied
        bytes32 leaf = keccak256(abi.encodePacked(_to, _tokenId));

        // verify the proof supplied, and return the verification result
        return _proof.verify(root, leaf);
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // withdraw the earnings to pay for the artists & devs :)
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function reclaimERC20(IERC20 erc20Token) public onlyOwner {
        erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
    }

    function reclaimERC721(IERC721 erc721Token, uint256 id) public onlyOwner {
        erc721Token.safeTransferFrom(address(this), msg.sender, id);
    }

    function reclaimERC1155(IERC1155 erc1155Token, uint256 id) public onlyDev {
        erc1155Token.safeTransferFrom(address(this), msg.sender, id, 1, "");
    }

    //in unix
    function setSaleStartTime(uint256 _saleStartTime) external onlyDev {
        saleStartTime = _saleStartTime;
    }

    // and for the eternity!
    function lockMetadata() external onlyDev {
        locked = true;
    }
}
