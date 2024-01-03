// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ISlopes {
    event Activated(address user);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Claim(address indexed user, uint256 indexed pid, uint256 pwdrAmount, uint256 tokenAmount);
    event ClaimAll(address indexed user, uint256 pwdrAmount, uint256[] tokenAmounts);
    event Migrate(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    // event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event PwdrPurchase(address indexed user, uint256 ethSpentOnPwdr, uint256 pwdrBought);

    function active() external view returns (bool);
    function pwdrSentToAvalanche() external view returns (uint256);
    function stakingFee() external view returns (uint256);
    function roundRobinFee() external view returns (uint256);
    function protocolFee() external view returns (uint256);

    function activate() external;
    function massUpdatePools() external;
    function updatePool(uint256 _pid) external;
    // function addPwdrReward(address _from, uint256 _amount) external virtual;
    // function addEthReward() external virtual payable;
    function claim(uint256 _pid) external;
    function claimAll() external;
    function claimAllFor(address _user) external;
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function migrate() external;
    function poolLength() external view returns (uint256);
    function addPool(address _token, address _lpToken, bool _lpStaked, uint256 _weight) external;
    function setWeight(uint256 _pid, uint256 _weight) external;
}

// interface ISlopes {
    

//     function activate() external;
//     function poolLength() external view returns (uint256);
//     function massUpdatePools() external;
//     function updatePool(uint256 _pid) external;
//     function deposit(uint256 _pid, uint256 _amount) external;
// }