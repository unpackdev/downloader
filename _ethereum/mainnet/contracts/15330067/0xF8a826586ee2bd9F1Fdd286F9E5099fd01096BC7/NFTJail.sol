/*
   . *@O°                . o@O°                  O@O.                 .#@o.                 °@@o.               . *@#o.
   . *@O°                . o@O°                . O@O° .             . .#@o. .             . °@@o. .             . *@#o.
     *@o.                  o@o.                  O@o.                 .##o.                 .@#o                  *@#*
****°o#Oo*****************°o#o**°°°**°°°°°°°°°°°°OOo**°°°°°°°°°°°°°°°°*OOo*°°°°°°°°°°°°°°°°°*OOo*°°°°°°°°°°°°°°°°°oOOo*°
.....o@@@#.................O@@@#.................#@@@O................°@@@@o................°@@@@*................o@@@@°
     *@##O                 o@##O                 O@##o                .@@##*                °@@##°                *@@##.
   . *@O°..              . o@O°.                 #@O°.                .@@o°.                °@@o°.              . *@#o°
   . *@O°                . o@O°                  #@O°               . .@@o°                 °@@o. . .  .        . *@#o.
   . *@O°        . .       o@O°                  O@O°                 .@@O°               . °@@o°         . .   . *@#o.
   . *@O°    ...     ...°..O@O° .        .     ..#@O.°*°°**°°**..°°°°°°@@o°                 °@@o°..°o.°*..    . . *@#o.
   . *@O°  .    °*°oO°*°.*@O@O°.**°°°.     ..°ooo#@O°°*o*********oooooo@@O.**°°..      ..°***@@o.*o#O °.OOo°*°  . *@#o.
   . *@O°   °**o#o*Oo*.  O#O@O°.oOO**o**°*o*o****#@O°°oooo********oo***@@O.°o*ooo*°.°°***oooo@@o°*@o o. @°o*@@O°  *@#o.
   . *@O° .##O@@°°*ooo# .@*O@O°.**#o***oO#O**ooo*#@O°.°°°**ooo*********@@O°°*****o#O*oooooooo@@o°°*@.° *@°*°#O#@* *@#o.
   . *@O° .@#O@#o°°**O#@°@oO@O°.oo***o@****oO*°. #@O°°*°.  ..o#********@@O.o@o****oO#o*o*****@@o.*@O °OO*O.Oo@OO@°*@#o.
   . *@O°   o@#o°*o°oO*°.. o@O° .°*°*#O****@°    #@O°°**. .. °@*******O@@O.*@Ooo***o#o*******@@o.°O.OOO*OO°#°* *@ *@#o.
   . *@O°   o@oO***o@      o@O°     °@*****#Oo***#@O°.°°****o#OooOO***o@@O.o@ooo*o*O* ..... °@@o°   OoOoO*°o°°°*@ *@#o.
   . *@O° .o#o°°*°**@ .  . o@O°   ...#O*****ooooo#@O°°OOOOoooo#@##@@o*o@@O°*oo****OO°     . °@@o° .  .*#.@.**oo*# *@#o°
   . *@O° o#°°°°oo°o#o .   o@O°  ... o#oo******o*#@O°.********o@##@@o**@@O°°***OOooO°       °@@o°   . .@O*.o*o.°@ *@#o°
   . *@O°  O#o*°*oo##  . °*O@O°       .°*oo******#@O°.*********oooo****#@o°°ooooO*°..°°°°°°.°@@o°    .OO*°o.*.oOO *@#o.
     *@O°   @*o**°°*Oo°  .°O@O°°#Oo°......°ooooOO#@O°°ooooOoooooooOOOOo@@O°°OooOOo#@#Oo**°° °@@o° . °@o°°O ***O*  *@#o.
.....*#o.   o°.°°°°°°*O*.°ooOo. o#OOoooooOOooooo*OO* .Oo°*O**oo**oOOoooOO* °o**oooO°°°   ...°OO*    *°  ....oO. ..*OO*
°°°°°*OOOo.°..°******°°°°°°oOOO*....ooOOoooooOo*ooOOooOO°*°°°*°°o#o°*ooOOoo*°oOooo*oo.°°°°°°°OOoo°.....°°°°°...°°.*Oooo°
     o@@@#     ......      O@@@O .°o@@##@@ooO###O@@@@@#o@o°°**°o*#@O .°@@@@Ooo##o**O#.      °@@@@° ... ....       *@@@@°
   . *@#OO               . o@#OO**oo    o@°##°.  #@#OOo#@****°**oo@@# .#@#O#.               °@@#O°              . *@@#O.
   . *@O°.               . o@O°..    °oooo°°.    #@O°**@@OOOooOO#@@o@..@@o°.  .  ...        °@@o°               . *@@o°

NFT Jail
An experimental project by Neon Nacho Labs
https://neonnacho.xyz

Find a bug? Let me know.
https://github.com/Neon-Nacho-Labs
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract NFTJail is ERC721, ERC721URIStorage, Ownable {
	using Counters for Counters.Counter;

	// Starts counting at 1 instead of 0
	Counters.Counter public tokenIdCounter;

	// Track minted tokens by parent address and id
	mapping (bytes32 => bool) public parentTokenTracker;

	constructor() ERC721("NFTJail", "NFTJAIL") {}

	function _baseURI() internal pure override returns(string memory) {
		return "ipfs://";
	}

	/**
	 * Go to jail!
	 * Mints an NFT based an existing one from a different contract.
	 */
	function mint(address parentContractAddress, uint256 parentTokenId, string calldata _tokenURI) external payable {
		bytes32 parentHash = keccak256(abi.encode(parentContractAddress, parentTokenId));
		// Each parent address/token can only be minted once
		require(!parentTokenTracker[parentHash], "Parent token already exists");

		// Caller must own the parent token
		require(msg.sender == IERC721(parentContractAddress).ownerOf(parentTokenId), "Caller does not own the parent token");

		// Keep track of parent tokens to prevent duplicates
		parentTokenTracker[parentHash] = true;

		tokenIdCounter.increment();
		_safeMint(msg.sender, tokenIdCounter.current());
		_setTokenURI(tokenIdCounter.current(), _tokenURI);
	}

	/**
	 * Allow funds to be withdrawn by the owner
	 */
	function withdrawAll() public onlyOwner {
        (bool success,) = payable(msg.sender).call{value : address(this).balance}("");
        require(success, "Withdrawal failed");
    }

	/**
	 * Receive function in case eth gets sent to the contract
	 */
	receive() external payable {}

	// Override functions
	function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}
