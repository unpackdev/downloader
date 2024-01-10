// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";

/*
 _____  _   _  _____   _____  _   _ ______  _   _  _____  _   _   ___   _        ___  ______  _____
|_   _|| | | ||  ___| /  ___|| | | || ___ \| | | ||_   _|| | | | / _ \ | |      / _ \ | ___ \|  ___|
  | |  | |_| || |__   \ `--. | | | || |_/ /| | | |  | |  | | | |/ /_\ \| |     / /_\ \| |_/ /| |__
  | |  |  _  ||  __|   `--. \| | | ||    / | | | |  | |  | | | ||  _  || |     |  _  ||  __/ |  __|
  | |  | | | || |___  /\__/ /| |_| || |\ \ \ \_/ / _| |_ \ \_/ /| | | || |____ | | | || |    | |___
  \_/  \_| |_/\____/  \____/  \___/ \_| \_| \___/  \___/  \___/ \_| |_/\_____/ \_| |_/\_|    \____/
*/

contract SurvivalApe is ERC721A, Ownable, ReentrancyGuard {

    struct COMB_MINT {
        uint256 wlType;
        bytes signature;
        uint256 mintAmount;
    }

    struct PRESALE_MINT {
        uint256 cost;
        uint256 wlType;
        uint256 maxMint;
    }

    using Strings for uint256;

    string public baseURI;
    bool public publicSaleIsActive = false;
    bool public preSaleIsActive = false;
    bool public combSaleIsActive = false;

    uint256 public cost = 0.15 ether;

    uint256 public maxSupply = 6666;
    uint256 public immutable maxMintAmountPerBatch = 10;
    address private signer;

    uint256[8] public preSaleCosts = [
    0.09 ether,
    0.11 ether,
    0 ether,
    0.12 ether,
    0.12 ether,
    0.12 ether,
    0.12 ether,
    0.12 ether
    ];

    mapping(uint256 => mapping(address => uint256)) public presaleWhiteListMints;
    mapping(uint256 => PRESALE_MINT) public presaleWalletListData;

    event WhiteListCostChanged(uint256[8] newCosts);
    event WhiteListMaxMintChanged(uint256[8] newMaxMints);
    event PublicCostChanged(uint256 newCost);

    constructor(
        string memory _name,
        string memory _symbol,
        address _signer
    ) ERC721A(_name, _symbol) {
        signer = _signer;
        for (uint i = 0; i < 8; i++) {
            uint256 wlCost = preSaleCosts[i];
            presaleWalletListData[i] = PRESALE_MINT(wlCost, i + 1, 1);
        }
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function publicMint(uint256 _mintAmount)
    public
    payable
    nonReentrant {
        uint256 supply = totalSupply();
        require(publicSaleIsActive, "public sale not open");
        require(tx.origin == msg.sender, "contract is not allowed to mint.");
        require(_mintAmount > 0, "mint num must > 0");
        require(supply + _mintAmount <= maxSupply, "cap reached");
        require(_mintAmount <= maxMintAmountPerBatch, "buy too much per tx");

        refundIfOver(cost * _mintAmount);
        _safeMint(msg.sender, _mintAmount);
    }

    function preSaleMint(uint256 _mintAmount, uint256 _wlType, bytes memory _signature)
    public
    payable
    nonReentrant {

        uint256 supply = totalSupply();

        require(preSaleIsActive, "presale not open");
        require(tx.origin == msg.sender, "contract is not allowed to mint.");
        require(_mintAmount > 0, "mint num must > 0");
        require(supply + _mintAmount <= maxSupply, "cap reached");

        //1 OG 2 contributor 3 freeMint 4 WL1 5 WL2 6 WL3 7 WL4 8 WL5
        require(_wlType > 0 && _wlType <= 8, "Invalid whitelist type");
        require(
            _mintAmount + presaleWhiteListMints[_wlType - 1][msg.sender] <= presaleWalletListData[_wlType - 1].maxMint,
                "presale mint amount per wallet exceeded"
        );
        refundIfOver(presaleWalletListData[_wlType - 1].cost * _mintAmount);
        address signerOwner = signatureWallet(msg.sender, _wlType, _mintAmount, _signature);
        require(signerOwner == signer, "Not authorized to mint");

        presaleWhiteListMints[_wlType-1][msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function combSaleMint(COMB_MINT[] memory combMints)
    public
    payable
    nonReentrant {

        uint256 supply = totalSupply();
        require(combSaleIsActive, "presale not open");
        require(tx.origin == msg.sender, "contract is not allowed to mint.");

        uint256 mintTotalAmount = 0;
        uint256 totalValue = 0;
        for (uint i = 0; i < combMints.length; i++) {
            COMB_MINT memory combMint = combMints[i];
            require(combMint.mintAmount > 0, "mint num must > 0");
            //1 OG 2 contributor 3 freeMint 4 WL1 5 WL2 6 WL3 7 WL4 8 WL5
            require(
                combMint.mintAmount + presaleWhiteListMints[combMint.wlType-1][msg.sender] <= presaleWalletListData[combMint.wlType-1].maxMint,
                    "presale mint amount per wallet exceeded"
            );
            address signerOwner = signatureWallet(msg.sender, combMint.wlType, combMint.mintAmount, combMint.signature);
            require(signerOwner == signer, "Not authorized to mint");
            mintTotalAmount += combMint.mintAmount;
            totalValue += combMint.mintAmount * presaleWalletListData[combMint.wlType-1].cost;
        }

        require(supply + mintTotalAmount <= maxSupply, "cap reached");
        refundIfOver(totalValue);

        for (uint i = 0; i < combMints.length; i++) {
            COMB_MINT memory combMint = combMints[i];
            presaleWhiteListMints[combMint.wlType-1][msg.sender] += combMint.mintAmount;
        }
        _safeMint(msg.sender, mintTotalAmount);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function signatureWallet(address wallet, uint256 _wlType, uint256 _mintAmount, bytes memory _signature)
    public
    pure
    returns (address)
    {
        return ECDSA.recover(keccak256(abi.encode(wallet, _wlType, _mintAmount)), _signature);
    }

    //only owner
    function setCost(uint256 _newCost) external onlyOwner {
        cost = _newCost;
        emit PublicCostChanged(_newCost);
    }

    function setPresaleCost(uint256[8] memory _newCosts) external onlyOwner {
        for (uint i = 0; i < 8; i++) {
            preSaleCosts[i] = _newCosts[i];
            presaleWalletListData[i].cost = _newCosts[i];
        }
        emit WhiteListCostChanged(_newCosts);
    }
    function setPresaleMaxMint(uint256[8] memory _newMaxMint) external onlyOwner {
        for (uint i = 0; i < 8; i++) {
            presaleWalletListData[i].maxMint = _newMaxMint[i];
        }
        emit WhiteListMaxMintChanged(_newMaxMint);
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setSigner(address _newSigner) external onlyOwner {
        signer = _newSigner;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setPublicSaleState(bool newState) external onlyOwner {
        publicSaleIsActive = newState;
    }

    function setPreSaleState(bool newState) external onlyOwner {
        preSaleIsActive = newState;
    }

    function setCombSaleState(bool newState) external onlyOwner {
        combSaleIsActive = newState;
    }

    function reserve(uint256 _n, address _receiver) external onlyOwner {
        uint256 supply = totalSupply();
        require(_receiver != address(0), "not zero address");
        require(_n > 0, "not zero amount");
        require(supply + _n <= maxSupply, "cap reached");

        _safeMint(_receiver, _n);
    }

    function batchReserve(address[] memory _receivers) external onlyOwner {
        uint256 supply = totalSupply();
        require(_receivers.length > 0, "not zero receivers");
        require(supply + _receivers.length <= maxSupply, "cap reached");
        for(uint i = 0; i< _receivers.length; i++) {
            require(_receivers[i] != address(0), "not zero address");
            _safeMint(_receivers[i], 1);
        }
    }

    function withdrawBalance(uint256 _amount) external onlyOwner {
        require(_amount <= address(this).balance,"withdraw amount too large");
        payable(msg.sender).transfer(_amount);
    }
}
