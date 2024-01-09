// SPDX-License-Identifier: MIT
// Developer: @Brougkr

pragma solidity ^0.8.10;
import "./ERC721.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract FOMO is ERC721, Ownable, Pausable
{
    using SafeMath for uint256;

    /*--------------------
        * VARIABLES *
    ---------------------*/

    //Initialization
    string public _BASE_URI = "ipfs://QmPL7b6Bv3YH3ytNzk3Qo9NkMGkfvPCG3Zo7jch7LMHBJW/";
    
    //Minted Token Amounts
    uint256 public _FOMOS_MINTED = 0;

    /*--------------------
        * CONSTRUCTOR *
    ---------------------*/

    constructor() ERC721("FOMO", "FOMO") { }

    /*--------------------
        * EXTERNAL *
    ---------------------*/

    //Sets Base URI For .json hosting
    function __setBaseURI(string calldata BASE_URI) external onlyOwner { _BASE_URI = BASE_URI; }

    /*--------------------
        * VIEW *
    ---------------------*/

    //URI for decoding storage of tokenIDs
    function tokenURI(uint256 tokenId) public view override returns (string memory) { return(string(abi.encodePacked(_BASE_URI, Strings.toString(tokenId), ".json"))); }

    //Shows Total Minted Supply
    function totalSupply() public view returns (uint supply) { return(_FOMOS_MINTED); }

    /*--------------------
        * ADMIN *
    ---------------------*/

    //Mints FOMO
    function FOMOMint() public onlyOwner
    {
        _mint(msg.sender, _FOMOS_MINTED);
        _FOMOS_MINTED += 1;
    }

    //Withdraws Ether from Contract
    function __withdrawEther(address to) external onlyOwner 
    { 
        require(address(this).balance > 0, "Zero Ether Balance");
        payable(to).transfer(address(this).balance); 
    }
    
    //Withdraws ERC-20
    function __withdrawERC20(address tokenAddress, address to) external onlyOwner 
    { 
        IERC20 erc20Token = IERC20(tokenAddress);
        require(erc20Token.balanceOf(address(this)) > 0, "Zero Token Balance");
        erc20Token.transfer(to, erc20Token.balanceOf(address(this))); 
    }

    //Pauses Contract
    function __pause() public onlyOwner { _pause(); }

    //Unpauses Contract
    function __unpause() public onlyOwner { _unpause(); }
}
