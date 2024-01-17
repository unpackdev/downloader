// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Pausable.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./Strings.sol";
import "./IERC20.sol";

import "./ERC721A.sol";

interface IWasteland is IERC20 {
    function burn(address _from, uint256 _ammount) external;
}

contract Comic is ERC721A, Ownable, Pausable, PaymentSplitter {
    using Strings for uint256;

    uint256 public ISSUE_SUPPLY = 500;
    uint256 public WSTLND_SUPPLY = 350;
    uint256 public WSTLND_MINTS;
    uint128 public PRICE = 0.3 ether;
    uint128 public WSTLND_PRICE = 350 ether;
    uint128 public MINT_LIMIT = 2;
    string internal baseTokenURI;
    address[] internal payees;

    IWasteland public WSTLND;

    mapping(address => uint256) public mintBalances;
    mapping(uint256 => bool) public redeemed;

    error NotAllowed();
    error NotTokenOwner();

    event Redeemed(address, uint256);
    event RedeemReturn(uint256);

    constructor(
        address[] memory _payees,
        uint256[] memory _shares,
        IWasteland WSTLNDAddress
    )
        payable
        ERC721A("KKWLCC Comic", "KKWLCC")
        Pausable()
        PaymentSplitter(_payees, _shares)
    {
        WSTLND = WSTLNDAddress;
        payees = _payees;
        _pause();
    }

    function purchase(uint256 _quantity) external payable whenNotPaused {
        require(_quantity <= MINT_LIMIT, "Quantity exceeds MINT_LIMIT");
        require(
            _quantity + mintBalances[msg.sender] <= MINT_LIMIT,
            "Quantity exceeds per-wallet limit"
        );
        require(_quantity * PRICE <= msg.value, "Not enough minerals");
        require(
            _quantity + totalSupply() <= ISSUE_SUPPLY,
            "Purchase exceeds available supply"
        );

        _mint(msg.sender, _quantity);

        mintBalances[msg.sender] += _quantity;
    }

    function purchaseWithWSTLND(uint256 _quantity) external whenNotPaused {
        require(_quantity <= MINT_LIMIT, "Quantity exceeds MINT_LIMIT");
        require(
            _quantity + mintBalances[msg.sender] <= MINT_LIMIT,
            "Quantity exceeds per-wallet limit"
        );
        require(
            WSTLND.balanceOf(msg.sender) >= WSTLND_PRICE * _quantity,
            "Not enough WSTLND"
        );
        require(
            _quantity + WSTLND_MINTS <= WSTLND_SUPPLY &&
                _quantity + totalSupply() <= ISSUE_SUPPLY,
            "Purchase exceeds available supply"
        );
        WSTLND.burn(msg.sender, WSTLND_PRICE * _quantity);
        _mint(msg.sender, _quantity);
        WSTLND_MINTS += _quantity;
        mintBalances[msg.sender] += _quantity;
    }

    function redeem(uint256 tokenId) external {
        if (ownerOf(tokenId) != msg.sender) revert NotTokenOwner();

        redeemed[tokenId] = true;
        emit Redeemed(msg.sender, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), '"ERC721Metadata: tokenId does not exist"');

        return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
    }

    // Only Owner
    function gift(address[] calldata _recipients) external onlyOwner {
        uint256 recipients = _recipients.length;
        require(
            recipients + totalSupply() <= ISSUE_SUPPLY,
            "recipients exceeds totalSupply"
        );

        for (uint256 i = 0; i < recipients; i++) {
            _mint(_recipients[i], 1);
        }
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseTokenURI = _URI;
    }

    function setPaused(bool _state) external onlyOwner {
        _state ? _pause() : _unpause();
    }

    function setPrice(uint128 _price) external onlyOwner {
        PRICE = _price;
    }

    function updateWSTLND(IWasteland WSTLNDAddress) external onlyOwner {
        WSTLND = WSTLNDAddress;
    }

    function setIssueSupply(uint256 _supply) external onlyOwner {
        ISSUE_SUPPLY = _supply;
    }

    function setWastelandSupply(uint256 _supply) external onlyOwner {
        WSTLND_SUPPLY = _supply;
    }

    function unredeem(uint256 tokenId) external onlyOwner {
        redeemed[tokenId] = false;
        emit RedeemReturn(tokenId);
    }

    function withdrawAll() external onlyOwner {
        for (uint256 i = 0; i < payees.length; i++) {
            release(payable(payees[i]));
        }
    }
}
