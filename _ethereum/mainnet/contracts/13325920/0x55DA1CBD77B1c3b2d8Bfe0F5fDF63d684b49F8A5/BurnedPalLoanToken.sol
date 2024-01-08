//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
pragma abicoder v2;
//SPDX-License-Identifier: MIT

import {Errors} from  "./utils/Errors.sol";
import "./SafeMath.sol";
import "./IPalLoanToken.sol";



/** @title BurnedPalLoanToken contract  */
/// @author Paladin
contract BurnedPalLoanToken{
    using SafeMath for uint;

    //Storage

    // Token name
    string public name;
    // Token symbol
    string public symbol;

    //Token Minter contract : PalLoanToken
    address public minter;

    uint256 public totalSupply;
    // Mapping from token ID to owner address
    mapping(uint256 => address) private owners;

    // Mapping owner address to token count
    mapping(address => uint256[]) private balances;


    //Modifiers
    modifier authorized() {
        //allows only the palLoanToken contract to call methds
        require(msg.sender == minter, Errors.CALLER_NOT_MINTER);
        _;
    }


    //Events

    /** @notice Event when a new token is minted */
    event NewBurnedLoanToken(address indexed to, uint256 indexed tokenId);


    //Constructor
    constructor(string memory _name, string memory _symbol) {
        //ERC721 parameters
        name = _name;
        symbol = _symbol;
        minter = msg.sender;
        totalSupply = 0;
    }



    //Functions


    //URI method
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return IPalLoanToken(minter).tokenURI(tokenId);
    }

    /**
    * @notice Return the user balance (total number of token owned)
    * @param owner Address of the user
    * @return uint256 : number of token owned (in this contract only)
    */
    function balanceOf(address owner) external view returns (uint256){
        require(owner != address(0), "ERC721: balance query for the zero address");
        return balances[owner].length;
    }


    /**
    * @notice Return owner of the token
    * @param tokenId Id of the token
    * @return address : owner address
    */
    function ownerOf(uint256 tokenId) external view returns (address){
        return owners[tokenId];
    }

    
    /**
    * @notice Return the list of all tokens owned by the user
    * @dev Return the list of user's tokens
    * @param owner User address
    * @return uint256[] : list of owned tokens
    */
    function tokensOf(address owner) external view returns(uint256[] memory){
        return balances[owner];
    }

    

    /**
    * @notice Mint a new token to the given address with the given Id
    * @dev Mint the new token with the correct Id (from the previous burned token)
    * @param to Address of the user to mint the token to
    * @param tokenId Id of the token to mint
    * @return bool : success
    */
    function mint(address to, uint256 tokenId) external authorized returns(bool){
        require(to != address(0), "ERC721: mint to the zero address");

        //Update Supply
        totalSupply = totalSupply.add(1);

        //Add the new token to storage
        balances[to].push(tokenId);
        owners[tokenId] = to;

        //Emit the correct Event
        emit NewBurnedLoanToken(to, tokenId);

        return true;
    }


}