// SPDX-License-Identifier: MIT
// Developer: @Brougkr

pragma solidity 0.8.10;
import "./IERC721Receiver.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./IArtBlocks.sol";

contract CryptoCitizenMintPackRedeemer is Ownable, Pausable, ReentrancyGuard
{    
    address private immutable _ERC20_BRT_TokenAddress = 0xe5FDf72aC93796500e3A96163597DAFCC1C41C52;             // BRT Ropsten Contract Address   
    address private immutable _BRTMULTISIG = 0xB96E81f80b3AEEf65CB6d0E280b15FD5DBE71937;                        // Bright Moments Multisig Address
    address private immutable _ArtBlocksMintingContractAddress = 0xDd06d8483868Cd0C5E69C24eEaA2A5F2bEaFd42b;    // ArtBlocks Ropsten Minting Contract
    address private immutable _ArtBlocksCoreContractAddress = 0xbDdE08BD57e5C9fD563eE7aC61618CB2ECdc0ce0;       // Artblocks Ropsten NFT Collection Contract
    address private immutable _GoldenTicketCity5 = 0xC2A3c3543701009d36C0357177a62E0F6459e8A9;                  // Golden Ticket City 5
    address private immutable _GoldenTicketCity6 = 0xE0D1Fa3fBd72db2eD179F80C0459B7dA93Fe4FE8;                  // Golden Ticket City 6
    address private immutable _GoldenTicketCity7 = 0x762F5C8137C445164c53e138da33032C21F44D65;                  // Golden Ticket City 7
    address private immutable _GoldenTicketCity8 = 0x0205f9cEb478FC77E2cDB77efD27B414dD31bAE5;                  // Golden Ticket City 8
    address private immutable _GoldenTicketCity9 = 0x1b02C7f98e62dDF1aC434C372A282E862b03acC6;                  // Golden Ticket City 9
    address private immutable _GoldenTicketCity10 = 0xB8d1611bE514202b60AdfcC8910F5A963E4Eb38D;                 // Golden Ticket City 10
    address private immutable _MintPack = 0x96952728f070927201c67672B5ca1A79CABC6E67;                           // Mint Pack 
    uint256 private immutable _ArtBlocksProjectID = 0;                                                          // Galactican Project ID                                                 
    uint256 private _index = 0;
    
    // Approves 500,000 for purchasing
    constructor() 
    { 
        __approveBRT(500000); 
        _transferOwnership(_BRTMULTISIG);
    }

    // Redeems CryptoCitizen Mint Pass
    function redeemMintPack(uint256 passportTokenID) public nonReentrant whenNotPaused
    {
        // === Ensures Message Sender Is Owner of Mint Pass & Redeems Mint Pass ===
        require(IERC721(_MintPack).ownerOf(passportTokenID) == msg.sender, "Sender Does Not Own Mint Pass With The Input Token ID");
        IERC721(_MintPack).transferFrom(msg.sender, _BRTMULTISIG, passportTokenID);

        // === Mints Galactican ===
        uint256 _ArtBlocksTokenID = _mintGalactican();
        IERC721(_ArtBlocksCoreContractAddress).transferFrom(address(this), msg.sender, _ArtBlocksTokenID);

        // === Redeems Cities 5-10 ===
        IERC721(_GoldenTicketCity5).transferFrom(_BRTMULTISIG, msg.sender, _index);
        IERC721(_GoldenTicketCity6).transferFrom(_BRTMULTISIG, msg.sender, _index);
        IERC721(_GoldenTicketCity7).transferFrom(_BRTMULTISIG, msg.sender, _index);
        IERC721(_GoldenTicketCity8).transferFrom(_BRTMULTISIG, msg.sender, _index);
        IERC721(_GoldenTicketCity9).transferFrom(_BRTMULTISIG, msg.sender, _index);
        IERC721(_GoldenTicketCity10).transferFrom(_BRTMULTISIG, msg.sender, _index);

        // === Increments Index ===
        _index += 1;
    }
    
    // Returns Amount Of Mint Passes Redeemed
    function readIndex() public view returns(uint256) { return _index; }

    // Mints Galactican From ArtBlocks Minting Contract
    function _mintGalactican() private returns (uint tokenID) { return IArtBlocks(_ArtBlocksMintingContractAddress).purchase(_ArtBlocksProjectID); }

    // Withdraws ERC20 Tokens to Multisig
    function __withdrawERC20(address tokenAddress) public onlyOwner 
    { 
        IERC20 erc20Token = IERC20(tokenAddress);
        require(erc20Token.balanceOf(address(this)) > 0, "Zero Token Balance");
        erc20Token.transfer(_BRTMULTISIG, erc20Token.balanceOf(address(this)));
    }  

    // Approves BRT for Galactican Purchasing
    function __approveBRT(uint256 amount) public onlyOwner { IERC20(_ERC20_BRT_TokenAddress).approve(_ArtBlocksMintingContractAddress, amount); }

    // Withdraws Ether to Multisig
    function __withdrawEther() public onlyOwner { payable(_BRTMULTISIG).transfer(address(this).balance); }

    // Withdraws NFT to Multisig
    function __withdrawNFT(address contractAddress, uint256 tokenID) public onlyOwner { IERC721(contractAddress).safeTransferFrom(address(this), _BRTMULTISIG, tokenID); }

    // Pauses Functionality
    function __pause() public onlyOwner { _pause(); }

    // Unpauses Functionality
    function __unpause() public onlyOwner { _unpause(); }
}
