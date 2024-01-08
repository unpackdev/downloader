// SPDX-License-Identifier: MIT
/*
               __  __                                        
              /\ \/\ \                                       
              \ \ \_\ \     __     _____   _____   __  __    
               \ \  _  \  /'__`\  /\ '__`\/\ '__`\/\ \/\ \   
                \ \ \ \ \/\ \L\.\_\ \ \L\ \ \ \L\ \ \ \_\ \  
                 \ \_\ \_\ \__/.\_\\ \ ,__/\ \ ,__/\/`____ \ 
                  \/_/\/_/\/__/\/_/ \ \ \/  \ \ \/  `/___/> \
                                     \ \_\   \ \_\     /\___/
                                      \/_/    \/_/     \/__/  
         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  
         @//@@                                                   @@//@
         @@////@@                                             @@////@@  
          @@/////@@                                         @@/////@@   
           @@//////@@         _____         _____         @@//////@@    
            @@///////@@      /     \       /     \      @@///////@@     
             @@////////@@                             @@////////@@      
               @@///////@@   ###               ###   @@///////@@        
                @@////////@@                       @@////////@@         
                  @@///////@@                     @@///////@@           
                    @@//////@@     \__/\__/      @@//////@@             
                      @@/////@@                 @@/////@@               
                        @@////@@               @@////@@                 
                          @@///@               @///@@                   
                            @@/@@             @@/@@                     
                               @@@@@@@@@@@@@@@@@                        
                                                                            
 */
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract HappyPanties is ERC721, ERC721Enumerable, Ownable {
	using SafeMath for uint256;

	uint256 public maxPanties = 2500;
	bool public salesIsOpen = false;
	uint256 public constant pantyPrice = 0.039 ether;
	
	constructor() ERC721("HappyPanties", "PANTIES") {}

	modifier salesOpen {
		if(_msgSender() != owner())
			require(salesIsOpen, "Direct sales are not open");
		_;
	}

	function contractURI() public pure returns (string memory) {
		return "https://api.happycollector.net/contract/panties";
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return "https://api.happycollector.net/token/panties/";
	}

	function mintTo(address to) private {
		uint tokenId = totalSupply();
		_safeMint(to, tokenId);
	}

	/*
	 * You know what it is :)
	 */
	function withdraw() public onlyOwner {
		uint balance = address(this).balance;
		payable(msg.sender).transfer(balance);
	}

	/*
	 * Allows to configure sales batch-by-batch
	 */
	function changeBatch(uint number) public onlyOwner {
		require(number > 0 && number <= 9999, "Max panties is 9999");
		maxPanties = number;
	}

	/*
	 * Give some panties
	 */
	function giveAway(uint number, address to) public onlyOwner {
		require(number > 0 && number <= 50, "Quantity must be between 1 and 50");
		require(to != address(0), "Address must be valid");
		for(uint i = 0; i < number; i++)
			mintTo(to);
	}

	/*
	 * Give all owners an another token.
	 */
	function rewardOwners() public onlyOwner {
		uint tokens = totalSupply();
		for(uint i = 0; i < tokens; i++)
			mintTo(ownerOf(i));
	}

	/*
	 * Resume or stop direct sales
	 */
	function switchSales() public onlyOwner {
		salesIsOpen = !salesIsOpen;
	}

	/*
	 * Direct sales
	 */
	function mint(uint number) public payable salesOpen {
		require(number > 0 && number <= 5, "We only sell pack of 5 panties!");
		require(pantyPrice.mul(number) <= msg.value, "Price is not correct");
		require(totalSupply().add(number) <= maxPanties, "No panties remaining!");
		for(uint i = 0; i < number; i++)
			mintTo(msg.sender);
	}

	/*
	 * Rewrite required due to inheritance
	 */
	function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
		super._beforeTokenTransfer(from, to, tokenId);
	}

	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
		return super.supportsInterface(interfaceId);
	}
}