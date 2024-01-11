//SPDX-License-Identifier: MIT
// Creator: Roman Gascoin

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./IERC20.sol";

error notWhiteListed();

contract TheKazokus is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public marketCap                    = 500;
    uint8   public cap_public                   = 3;

    enum locked {CLOSED, PUBLIC}
    locked public lockState = locked.CLOSED;

    string  private uri_base = 'https://resolver-art.nftkazoku.com/resolver/';

    constructor() ERC721A("The Kazokus", "The Kazokus") {}

    //-------------------------------------------SETTERS PART----------------------------------------------------------

    /**
     * @dev Change the Contract state for minting purpose.
     */
    function setLock(locked _value)
    onlyOwner external {
        lockState = _value;
    }

    /**
     * @dev change the baseUri for tokenURI function.
     If baseUri is '' the DefaultUri value is used.
     */
    function setBaseUri(string memory _value)
    onlyOwner external {
        uri_base = _value;
    }

    //-------------------------------------------MODIFIER PART----------------------------------------------------------

    /**
     * @dev Used with the Contract state, for open or close minting.
     */
    modifier isOpenFor(locked _value) {
        if (_value == locked.PUBLIC) {
            require(lockState == locked.PUBLIC, "Error: Mint is closed.");
        }
        _;
    }

    /**
     * @dev Check if the requested minted token is under the marketCap limit
     */
    modifier isMarketCaped(uint256 _quantity) {
        require(totalSupply() + _quantity <= marketCap, "Error: no enough token remaining.");
        _;
    }

    //------------------------------------------TOOLS FUNCTION PART-----------------------------------------------------

    /**
     * @dev override the _baseURI function to return a variable element instead of hardcode string.
     */
    function _baseURI() internal view override returns (string memory) {
        return uri_base;
    }

    //-------------------------------------------MINT FUNCTION PART-----------------------------------------------------

    /**
     * @dev Allow a public user to mint NFT.
     */
    function mint_public(uint8 _quantity) external
    isOpenFor(locked.PUBLIC)
    isMarketCaped(_quantity) {
        require(balanceOf(_msgSender()) + _quantity <= cap_public, "Error: You can't mint more.");
        _safeMint(_msgSender(), _quantity);
    }

    //---------------------------------------WITHDRAW FUNCTION PART-----------------------------------------------------

    /**
     * @dev Withdraw all of the ETH stored in this contract.
     Give 15 of the amount to the wonderful Rgascoin.
     */
    function withdraw() external onlyOwner {
        payable(0xd87c0f9734e3FB6370F12D78Ef02d756e5b2C600).transfer(address(this).balance);
    }

    /**
     * @dev Allow to claim loosed ERC20 stored in this contract.
     */
    function reclaimERC20(IERC20 erc20Token) external onlyOwner {
        erc20Token.transfer(_msgSender(), erc20Token.balanceOf(address(this)));
    }
}