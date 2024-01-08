// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./Mintable.sol";

contract PigsGameBarns is ERC721, Ownable, Mintable {
    string public baseURI;
    bool public sale;
    bool public presale;
    uint256 public maxSupply;
    uint256 public maxPerTx;
    uint256 public maxPerTxPre;
    uint256 public pricePer;
    uint256 public pricePerPre;
    uint256 public maxPreMint;
    uint256 public maxWallet = 5;
    uint256 public totalSupplied = 0;
    bytes32 public mr;
    mapping(address => uint256) public mintedLog; // To check how many tokens an address has minted
    event Deposit(address indexed _from, uint256 _value, uint256 _nfcount);

    function _mintFor(
        address user,
        uint256 id,
        bytes memory
    ) internal override {
        _safeMint(user, id);
    }

    constructor(
        address _owner,
        address _imx,
        uint256 maxSupply_,
        uint256 maxPerTx_,
        uint256 maxPerTxPre_,
        uint256 pricePer_,
        uint256 pricePerPre_
    ) ERC721("PigsGameBarns", "PBARN") Mintable(_owner, _imx) {
        imx = _imx;
        require(_owner != address(0), "Owner must not be empty");
        transferOwnership(_owner);
        maxSupply = maxSupply_;
        maxPerTx = maxPerTx_;
        maxPerTxPre = maxPerTxPre_;
        pricePer = pricePer_;
        pricePerPre = pricePerPre_;
        sale = false;
        presale = false;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _bu) external onlyOwner {
        baseURI = _bu;
    }

    function setMerkleRoot(bytes32 _mr) external onlyOwner {
        mr = _mr;
    }

    function toggleSale(bool _s, bool _ps) external onlyOwner {
        sale = _s;
        presale = _ps;
    }

    function setContractRules(
        uint256 _mS,
        uint256 _nMPM,
        uint256 _nMPTX,
        uint256 _nMPTXPr,
        uint256 _nMW,
        uint256 _nPPre,
        uint256 _nPPu
    ) external onlyOwner {
        maxSupply = _mS;
        maxPreMint = _nMPM;
        maxPerTx = _nMPTX;
        maxPerTxPre = _nMPTXPr;
        maxWallet = _nMW;
        pricePerPre = _nPPre;
        pricePer = _nPPu;
    }

    function giveaway(address _to, uint8 _qty) external onlyOwner {
        require(_qty <= maxPerTx, "Rq qty more than max");

        totalSupplied += _qty;
        mintedLog[msg.sender] += _qty;
        emit Deposit(_to, 0, _qty);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function checkTokenExists(uint256 tokenId) public view returns (bool) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return true;
    }

    function transfer(uint256 _qty) external payable {
        // Sale must be enabled
        require(sale, "Sale not on");
        require(_qty != 0, "Rq qty cant be 0");
        require(_qty <= maxPerTx, "Rq qty > maximum");
        require(_qty * pricePer <= msg.value, "Not enough ether sent");
        require(
            totalSupplied + _qty <= maxSupply,
            "Prch exceeds max pub sale tokens"
        );
        require(
            mintedLog[msg.sender] + _qty <= maxWallet,
            "Prch exceeds max tokens/wallet"
        );
        require(!Address.isContract(msg.sender), "No Contracts");
        totalSupplied += _qty;
        mintedLog[msg.sender] += _qty;
        emit Deposit(msg.sender, msg.value, _qty);
    }

    function transferPreSale(uint256 _qty, bytes32[] calldata _mp)
        external
        payable
    {
        // Sale must NOT be enabled
        require(!sale, "Sale already in progress");
        require(presale, "Presale must be active");
        require(_qty != 0, "Rq qty cannot be 0");
        require(_qty <= maxPerTxPre, "Rq qty > maximum pre");
        require(_qty * pricePerPre <= msg.value, "Not enough ether sent");
        require(
            totalSupplied + _qty <= maxPreMint,
            "Prch would exceed max tokens for presale"
        );
        require(
            mintedLog[msg.sender] + _qty <= maxPerTxPre,
            "Prch exceeds max presale tokens"
        );
        require(
            mintedLog[msg.sender] + _qty <= maxWallet,
            "Prch exceeds max tokens/wallet"
        );
        require(!Address.isContract(msg.sender), "No Contracts");

        address sender = _msgSender();
        bytes32 leaf = keccak256(abi.encodePacked(sender));
        require(MerkleProof.verify(_mp, mr, leaf), "Not VIP");

        totalSupplied += _qty;
        mintedLog[msg.sender] += _qty;
        emit Deposit(msg.sender, msg.value, _qty);
    }
}
