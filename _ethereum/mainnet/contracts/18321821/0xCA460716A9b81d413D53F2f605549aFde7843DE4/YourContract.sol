//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/*
                                                                                    
  ####   ####  #    #  ####  #        ##   #####   ####  #    # # #####                   
 #      #    # #    # #    # #       #  #  #    # #      #    # # #    #                  
  ####  #      ###### #    # #      #    # #    #  ####  ###### # #    #                  
      # #      #    # #    # #      ###### #####       # #    # # #####                   
 #    # #    # #    # #    # #      #    # #   #  #    # #    # # #                       
  ####   ####  #    #  ####  ###### #    # #    #  ####  #    # # #                       
                                                                                          
                                                                                          
     #####  #    # # #####  #       ####  #    # # #####  #           ####   ####  #    # 
     #    # #    # # #    # #      #    # #    # # #    # #          #    # #    # ##  ## 
     #####  #    # # #    # #      #      #    # # #    # #          #      #    # # ## # 
 ### #    # #    # # #    # #      #  ### #    # # #    # #      ### #      #    # #    # 
 ### #    # #    # # #    # #      #    # #    # # #    # #      ### #    # #    # #    # 
 ### #####   ####  # #####  ######  ####   ####  # #####  ###### ###  ####   ####  #    # 
                                                                                          
 */
contract ENSContract {
	function setName(string memory newName) public {
		//do something
	}
}
contract IERC20 {
	function transfer(address recipient, uint256 amount) public returns (bool) {
		//do something
	}
}

contract IERC721 {
	function transferFrom(address from, address to, uint256 tokenId) public {
		//do something
	}
}

contract YourContract {

	address public immutable owner = 0x34aA3F359A9D614239015126635CE7732c18fDF3;
	ENSContract public immutable ensContract = ENSContract(0xa58E81fe9b61B5c3fE2AFD33CF304c454AbFc7Cb);

	function setName(string memory newName) public {
		require(msg.sender == owner, "Only the owner can change the name");
		ensContract.setName(newName);
	}

	function transferERC20(address tokenAddress, address recipient, uint256 amount) public {
		require(msg.sender == owner, "Only the owner can transfer ERC20");
		IERC20(tokenAddress).transfer(recipient, amount);
	}

	function transferERC721(address tokenAddress, address recipient, uint256 tokenId) public {
		require(msg.sender == owner, "Only the owner can transfer ERC721");
		IERC721(tokenAddress).transferFrom(address(this), recipient, tokenId);
	}

	mapping(address => bool) public canSendEther;

	constructor() {
		canSendEther[owner] = true;
	}

	event CanSendEther(address indexed user, bool canSend);

	function setCanSendEther(address user, bool canSend) public {
		require(msg.sender == owner, "Only the owner can change the name");
		canSendEther[user] = canSend;
		emit CanSendEther(user, canSend);
	}

	event EtherSent(address indexed recipient, uint256 amount);

	function sendEther(address payable recipient, uint256 amount) public {
		require(canSendEther[msg.sender], "You are not allowed to send Ether");
		(bool success,) = recipient.call{value: amount}("");
		require(success, "Failed to send Ether");
		emit EtherSent(recipient, amount);
	}

	receive() external payable {}
}
