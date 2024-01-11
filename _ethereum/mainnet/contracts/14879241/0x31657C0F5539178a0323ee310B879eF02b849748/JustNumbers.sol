// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "ERC721A.sol";
import "Context.sol";
import "Ownable.sol";
import "ERC2981.sol";

contract JustNumbers is Ownable, ERC721A, ERC2981 {
    uint256 public maxSupply                    = 5000;
    uint256 public maxFreeSupply                = 1000;
    
    uint256 public maxPerTxDuringMint           = 40;
    uint256 public maxPerAddressDuringMint      = 400;
    uint256 public maxPerAddressDuringFreeMint  = 5;
    
    uint256 public price                        = 0.002 ether;
    bool    public saleIsActive                 = false;

    address constant internal TEAM_ADDRESS = 0xfE4E7eAf4398f2D36f98081888CC6894c9822ad1;

    string private _baseTokenURI;
    
    uint96 private contractRoyalties = 400; //4%
    address private royaltyReceiver;



    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721A(_name, _symbol) {
        royaltyReceiver = owner();
        _setDefaultRoyalty(royaltyReceiver, contractRoyalties); // set intial default royalties
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setTokenRoyalties(uint96 _royalties) external onlyOwner {
        contractRoyalties = _royalties;
        _setDefaultRoyalty(royaltyReceiver, contractRoyalties);
    }

    function setRoyaltyPayoutAddress(address _payoutAddress)
        external
        onlyOwner
    {
        royaltyReceiver = _payoutAddress;
        _setDefaultRoyalty(royaltyReceiver, contractRoyalties);
    }

    modifier mintCompliance {
        require(saleIsActive, "Sale is not active yet.");
        require(tx.origin == msg.sender, "Caller cannot be a contract.");
        _;
    }

    function mint(uint256 _quantity) external payable mintCompliance {
        require(
            msg.value >= price * _quantity,
            "Insufficient Fund."
        );
        require(
            maxSupply >= totalSupply() + _quantity,
            "Exceeds max supply."
        );
        uint256 _mintedAmount = _numberMinted(msg.sender);
        require(
            _mintedAmount + _quantity <= maxPerAddressDuringMint,
            "Exceeds max mints per address!"
        );
        require(
            _quantity > 0 && _quantity <= maxPerTxDuringMint,
            "Invalid mint amount."
        );
        _safeMint(msg.sender, _quantity);
    }

    function freeMint(uint256 _quantity) external mintCompliance {
        require(
            maxFreeSupply >= totalSupply() + _quantity,
            "Exceeds max free supply."
        );
        uint256 mints = _numberMinted(msg.sender);
        require(
            mints + _quantity <= maxPerAddressDuringFreeMint,
            "Exceeds max free mints per address!"
        );
        _safeMint(msg.sender, _quantity);
    }

    function claimFreeNumber() external mintCompliance {
        require(
            maxSupply > totalSupply(),
            "Exceeds max supply."
        );
        uint256 mints = _numberMinted(msg.sender);
        require(mints == 0, "Already a number minter!");
        _safeMint(msg.sender, 1);
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMaxPerTx(uint256 _amount) external onlyOwner {
        maxPerTxDuringMint = _amount;
    }

    function setMaxPerAddress(uint256 _amount) external onlyOwner {
        maxPerAddressDuringMint = _amount;
    }

    function setMaxFreePerAddress(uint256 _amount) external onlyOwner {
        maxPerAddressDuringFreeMint = _amount;
    }

    function flipSale() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function cutMaxSupply(uint256 _amount) public onlyOwner {
        require(
            maxSupply - _amount >= totalSupply(), 
            "Supply cannot fall below minted tokens."
        );
        maxSupply -= _amount;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function withdrawBalance() external payable onlyOwner {

        (bool success, ) = payable(TEAM_ADDRESS).call{
            value: address(this).balance
        }("");
        require(success, "transfer failed.");
    }
}