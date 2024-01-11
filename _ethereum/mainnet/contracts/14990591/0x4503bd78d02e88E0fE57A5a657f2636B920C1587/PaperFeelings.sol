pragma solidity ^0.8.0;

import "./ERC721Base.sol";

contract PaperFeelings is ERC721Base {
    //    main sale
    uint256 public price;

    event SetPrice(uint256 _price);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        string memory _contractURI,
        address _proxyRegistry,
        uint256 _price
    ) ERC721Base(_name, _symbol, _baseUri, _contractURI, _proxyRegistry) {
        maxTotalSupply = 984;
        price = _price;
    }

    function mint(address _to, uint256 _amount) payable external {
        require(
            msg.value >= _amount * price,
            "PaperFeelings: tx value is too small"
        );
        require(
            _amount <= 15,
            "PaperFeelings: Too many tokens in one tx"
        );
        require(
            lastTokenId_ + _amount <= maxTotalSupply,
            "PaperFeelings: Cannot mint more tokens than the maxTotalSupply"
        );
        _mintTokens(_to, _amount);
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
        emit SetPrice(_price);
    }

    /**
        @notice Used to protect Owner from shooting himself in a foot
        @dev This function overrides same-named function from Ownable
             library and makes it an empty one
    */
    function renounceOwnership() public override onlyOwner {}
}
