//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//    ___ ___    _____      _____      _____    .___ _______   ____  __. _________            
//   /   |   \  /  _  \    /     \    /     \   |   |\      \ |    |/ _| \_   ___ \  ____     
//  /    ~    \/  /_\  \  /  \ /  \  /  \ /  \  |   |/   |   \|      <   /    \  \/ /  _ \    
//  \    Y    /    |    \/    Y    \/    Y    \ |   /    |    \    |  \  \     \___(  <_> )   
//   \___|_  /\____|__  /\____|__  /\____|__  / |___\____|__  /____|__ \  \______  /\____/ /\ 
//         \/         \/         \/         \/              \/        \/         \/        \/ 

interface Icollection {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory);
}