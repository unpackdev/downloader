// SPDX-License-Identifier: MIT
// Developer: @Brougkr

pragma solidity ^0.8.9;
import "./IERC721.sol";
import "./IERC20.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IArtBlocks.sol";

contract CryptoCitizenLiveMint is Ownable, Pausable, ReentrancyGuard
{   
    address private immutable _ERC20_BRT_TokenAddress = 0x7Fee6e7FAf98af42eb83f3aA882d99D3D6aD4940;             //BRTNY Mainnet Contract Address   
    address private immutable _BRTMULTISIG = 0xB96E81f80b3AEEf65CB6d0E280b15FD5DBE71937;                        //Bright Moments Multisig Mainnet Address    
    address private immutable _ArtBlocksMintingContractAddress = 0x47e312d99C09Ce61A866c83cBbbbED5A4b9d33E7;    //ArtBlocks Mainnet Minting Contract
    address private immutable _ArtBlocksCoreContractAddress = 0xa7d8d9ef8D8Ce8992Df33D8b8CF4Aebabd5bD270;       //Artblocks Mainnet NFT Collection Contract
    address private immutable _GoldenTicketAddress = 0xd43529990F3FbA41Affd66C4A8Ab6C1b7292D9Dc;                //Golden Ticket Mainnet Address                                                
    uint256 private immutable _ArtBlocksProjectID = 189;                                                        //CNY ArtBlocks Project ID
    mapping (uint256 => address) private mintingWhitelist;
    
    // Pre-Approves 1000 BRT For Purchasing (denoted in WEI)
    constructor() { approveBRT(1000000000000000000000); }

    // Sends Golden Ticket & Whitelists Address to receive CryptoCitizen
    function _whitelistGT(uint256 ticketTokenID) public nonReentrant
    {
        require(IERC721(_GoldenTicketAddress).ownerOf(ticketTokenID) == msg.sender, "Sender Does Not Own Ticket With The Input Token ID");
        IERC721(_GoldenTicketAddress).safeTransferFrom(msg.sender, _BRTMULTISIG, ticketTokenID);
        mintingWhitelist[ticketTokenID] = msg.sender;
    }

    // Mints NFT to address
    function _LiveMint(uint256 ticketTokenID) public onlyOwner
    {
        address to = readWhitelist(ticketTokenID);
        require(to != address(0), "Golden Ticket Entered Is Not Whitelisted");
        uint256 tokenID = mintArtBlocks();
        sendTo(to, tokenID);
    }

    // Step 1: Approves BRT for spending on ArtBlocks Contract (denoted in wei)
    function approveBRT(uint256 amount) public onlyOwner { IERC20(_ERC20_BRT_TokenAddress).approve(_ArtBlocksMintingContractAddress, amount); }

    // Step 2: Mints CryptoCitizen NFT
    function mintArtBlocks() private onlyOwner returns (uint tokenID) { return IArtBlocks(_ArtBlocksMintingContractAddress).purchase(_ArtBlocksProjectID); }

    // Step 3: Sends tokenID to the "to" address specified
    function sendTo(address to, uint256 tokenID) private onlyOwner { IERC721(_ArtBlocksCoreContractAddress).safeTransferFrom(address(this), to, tokenID); }

    // Reads Whitelisted Address Corresponding to GoldenTicket TokenID
    function readWhitelist(uint256 tokenID) public view returns(address) { return mintingWhitelist[tokenID]; }

    // Withdraws ERC20 Tokens to Multisig
    function withdrawERC20(address tokenAddress) public onlyOwner 
    { 
        IERC20 erc20Token = IERC20(tokenAddress);
        require(erc20Token.balanceOf(address(this)) > 0);
        erc20Token.transfer(_BRTMULTISIG, erc20Token.balanceOf(address(this)));
    }  

    // Withdraws Ether to Multisig
    function withdrawEther() public onlyOwner { payable(_BRTMULTISIG).transfer(address(this).balance); }
}
