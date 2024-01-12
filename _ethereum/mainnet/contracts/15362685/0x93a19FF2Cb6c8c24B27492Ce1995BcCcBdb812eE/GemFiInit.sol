// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import "./IERC165.sol";
import "./IERC721Metadata.sol";
import "./IERC721.sol";
import "./IERC2981.sol";
import "./LibDiamond.sol";
import "./IDiamondLoupe.sol";
import "./IDiamondCut.sol";
import "./IERC173.sol";
import "./IERC721A.sol";
import "./Constants.sol";
import "./BaseContract.sol";
import "./AppStorage.sol";
import "./console.sol";

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init funciton if you need to.

contract GemFiInit is
	BaseContract
{    
	// You can add parameters to this function in order to pass in 
    // data to set your own state variables
    function init()
		external onlyOwner
	{	
        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
		ds.supportedInterfaces[type(IERC721A).interfaceId] = true;
		ds.supportedInterfaces[type(IERC721).interfaceId] = true;
		ds.supportedInterfaces[type(IERC721Metadata).interfaceId] = true;
		ds.supportedInterfaces[type(IERC2981).interfaceId] = true;

		AppStorage.State storage s = AppStorage.getState();
		s.name = Constants.NAME;
		s.symbol = Constants.SYMBOL;
		s.version = Constants.VERSION;
		s.description = Constants.DESCRIPTION;

		s.paused = false;

		s.tokenBaseExternalUrl = "https://nft.gemfi.vip/static/nft/ETH/MASK/";
		s.contractLevelImageUrl = "https://nft.gemfi.vip/static/nft/ETH/MASK/image/0.png";
		s.contractLevelExternalUrl = "https://www.gemfi.vip";
		s.wlMinting = true;
		
		s.royaltyWalletAddress = Constants.ROYALTY_WALLET_ADDRESS;
		s.royaltyBasisPoints = Constants.ROYALTY_BASIS_POINTS;

		s.whitelistingSignatureAddress = LibDiamond.contractOwner();
		s.publicPoolRemaining = Constants.MAX_FREE_MINT_SUPPLY;

		// PROOF config
		s.proofPoolRemaining = Constants.MAX_PROOF_MINT_SUPPLY;
		s.proofToken = Constants.PROOF_TOKEN;
		s.proofMinting = false;

		// projectParty config
		s.projectPartyPoolRemaining = Constants.MAX_PROJECTPARTY_SUPPLY;

		s.whitelistingSignatureAddress = Constants.WHITELISTING_SIGNATURE_ADDRESS;

		s.defaultMintPROOFAddress = Constants.DEFAULT_MINT_PROOF_ADDRESS;
		s.defaultMintProjectPartyAddress = Constants.DEFAULT_MINT_PROJECT_PARTY_ADDRESS;


        // add your own state variables 
        // EIP-2535 specifies that the `diamondCut` function takes two optional 
        // arguments: address _init and bytes calldata _calldata
        // These arguments are used to execute an arbitrary function using delegatecall
        // in order to set state variables in the diamond during deployment or an upgrade
        // More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface 
    }


}