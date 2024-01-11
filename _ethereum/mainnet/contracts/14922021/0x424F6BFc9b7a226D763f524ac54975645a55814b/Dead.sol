//      .'(   )\.---.          /`-.      /`-.   )\.---.          /`-.    .')       .')                  
//  ,') \  ) (   ,-._(       ,' _  \   ,' _  \ (   ,-._(       ,' _  \  ( /       ( /                   
// (  /(/ /   \  '-,        (  '-' (  (  '-' (  \  '-,        (  '-' (   ))        ))                   
//  )    (     ) ,-`         )   _  )  ) ,_ .'   ) ,-`         )   _  )  )'._.-.   )'._.-.              
// (  .'\ \   (  ``-.       (  ,' ) \ (  ' ) \  (  ``-.       (  ,' ) \ (       ) (       )             
//  )/   )/    )..-.(        )/    )/  )/   )/   )..-.(        )/    )/  )/,__.'   )/,__.'              
//    )\.-.      .-./(  .'(   )\  )\     )\.-.        .-,.-.,-.    .-./(          )\.-.  .'(   )\.---.  
//  ,' ,-,_)   ,'     ) \  ) (  \, /   ,' ,-,_)       ) ,, ,. (  ,'     )       ,'     ) \  ) (   ,-._( 
// (  .   __  (  .-, (  ) (   ) \ (   (  .   __       \( |(  )/ (  .-, (       (  .-, (  ) (   \  '-,   
//  ) '._\ _)  ) '._\ ) \  ) ( ( \ \   ) '._\ _)         ) \     ) '._\ )       ) '._\ ) \  )   ) ,-`   
// (  ,   (   (  ,   (   ) \  `.)/  ) (  ,   (           \ (    (  ,   (       (  ,   (   ) \  (  ``-.  
//  )/'._.'    )/ ._.'    )/     '.(   )/'._.'            )/     )/ ._.'        )/ ._.'    )/   )..-.(  
//                                                                                                     
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC20.sol";
import "./IERC721.sol";

contract DEAD is ERC20 {

    IERC721 immutable public wagdie;
    mapping(uint256 => bool) public claimed;
    uint256 constant public tithe = 6666 * 10**18;
    uint256 constant public sacrificeMultiplier = 6;
    event Claim(address indexed from, uint256 amount);
    event Sacrifice(address indexed from, uint256 indexed tokenId, uint256 amount);

    constructor(address wagdieAddress) ERC20("Coins for the Dead", "DEAD") {
        wagdie = IERC721(wagdieAddress);
    }

    /// @notice you will need to approve your token first
    /// @notice 1) visit the contract page of wagdie (0x659A4BdaAaCc62d2bd9Cb18225D9C89b5B697A5A) 
    /// @notice 2) select "Write Contract"
    /// @notice 3) connect to Web3, then click on approve
    /// @notice 4) to: this contract address, tokenId: the id of the token you want to burn
    /// @notice 5) click on write
    /// @notice 6) confirm in metamask
    /// @notice 7) wait for confirmation
    function sacrifice(uint256 tokenId) external {
        wagdie.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, tokenId);
        _mint(msg.sender, sacrificeMultiplier * tithe);
        emit Sacrifice(msg.sender, tokenId, sacrificeMultiplier * tithe);
    }

    function claim(uint256 tokenId) external {
        verify(tokenId);
        _mint(msg.sender, tithe);
        emit Claim(msg.sender, tithe);
    }

    function claimMultiple(uint256[] calldata tokenIds) external {
        uint256 length = tokenIds.length;
        for (uint256 i; i < length;) {
            verify(tokenIds[i]);
            unchecked { ++i; }
        }
        _mint(msg.sender, tithe * length);
        emit Claim(msg.sender, tithe * length);
    }

    function verify(uint256 tokenId) internal {
        require(wagdie.ownerOf(tokenId) == msg.sender,  "Your boat had a hole in - drowned in the river Styx.");
        require(!claimed[tokenId],                      "You've already made it across the river Styx.");
        claimed[tokenId] = true;
    }
}