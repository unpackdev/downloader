// SPDX-License-Identifier: AGPL-3.0-or-later


pragma solidity 0.8.7;

import "./IERC20.sol";
import "./IERC721.sol";

// modified from disper.app
// optimize & add disperseERC721
// use at your own risk.
// editor : _bing
contract DisperseA {
	
	address private deployer;
	
	constructor(){ deployer = msg.sender; }
	
    function disperseEther(address[] calldata recipients, uint256[] calldata values) external payable {
        uint256 recipientsLength =  recipients.length;
		for (uint256 i = 0; i < recipientsLength;){
            payable(recipients[i]).transfer(values[i]);
			unchecked{ ++i; }
		}
        uint256 balance = address(this).balance;
        if (balance > 0)
            payable(deployer).transfer(balance);
    }

    function disperseToken(IERC20 token, address[] calldata recipients, uint256[] calldata values) external {
        uint256 i;
		uint256 total = 0;
		uint256 recipientsLength =  recipients.length;
        for (i = 0; i < recipientsLength; ){
			total += values[i];
			unchecked{ ++i; }
		}
        require(token.transferFrom(msg.sender, address(this), total));
        for (i = 0; i < recipientsLength; ){
            require(token.transfer(recipients[i], values[i]));
			unchecked{ ++i; }
		}
    }

    function disperseTokenSimple(IERC20 token, address[] calldata recipients, uint256[] calldata values) external {
		uint256 recipientsLength =  recipients.length;
		for (uint256 i = 0; i < recipientsLength; ){
            require(token.transferFrom(msg.sender, recipients[i], values[i]));
			unchecked{ ++i; }
		}
    }
	
	function disperseERC721(IERC721 NFT, address[] calldata recipients, uint256[] calldata token_id) external {
        for (uint256 i = 0; i < recipients.length;){
            NFT.transferFrom(msg.sender, recipients[i], token_id[i]);
			unchecked{ ++i; }
		}
    }
}