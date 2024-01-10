//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//    ___ ___    _____      _____      _____    .___ _______   ____  __. _________            
//   /   |   \  /  _  \    /     \    /     \   |   |\      \ |    |/ _| \_   ___ \  ____     
//  /    ~    \/  /_\  \  /  \ /  \  /  \ /  \  |   |/   |   \|      <   /    \  \/ /  _ \    
//  \    Y    /    |    \/    Y    \/    Y    \ |   /    |    \    |  \  \     \___(  <_> )   
//   \___|_  /\____|__  /\____|__  /\____|__  / |___\____|__  /____|__ \  \______  /\____/ /\ 
//         \/         \/         \/         \/              \/        \/         \/        \/ 

interface Ihamm {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function mint(address to, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}