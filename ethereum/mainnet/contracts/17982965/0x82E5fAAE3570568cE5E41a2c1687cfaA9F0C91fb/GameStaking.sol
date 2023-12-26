/**
 *Submitted for verification at Etherscan.io on 2023-08-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721{
    function balanceOf(address owner) external view returns (uint256 balance);    
    function transferFrom(address from, address to, uint256 tokenId) external;
    function tokenOfOwnerByIndex(address owner, uint256 index) external  view  returns (uint256);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract GameStaking{
    address SanshiNFT = 0x6976Af8b25C97A090769Fa97ca9359c891353f61;
    address owner;
    bool public unstake_enable = true;
    mapping(address => uint256) public _balances;
    mapping(address => mapping(uint256 => uint256)) public _tokensOfOwners; // address of Owner => (number in stacking => NFT ids)

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function tokensOfOwner_NFT(address _owner, uint256 _start, uint256 _end) external view returns(uint256[] memory) {
        uint256[] memory tokensId = new uint256[](_end - _start);
        for(uint i = _start; i < _end; i++){
            tokensId[i] = IERC721(SanshiNFT).tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function depositNft(uint256[] memory tokenIds) public {
        address Staker = msg.sender;
        require(IERC721(SanshiNFT).isApprovedForAll(Staker, address(this)), ": Game token consumption not allowed");
        for(uint i = 0; i < tokenIds.length; i++){
            IERC721(SanshiNFT).transferFrom(Staker, address(this), tokenIds[i]); //transfer the token with the specified id to the balance of the staking contract
            _balances[Staker]++; //increase staker balance
            uint256 Staker_balance = _balances[Staker];            
            _tokensOfOwners[Staker][Staker_balance] = tokenIds[i]; // We remember the token id on the stack in order           
        }
    }

    function unstakeNft(uint256 _count) public {
        address Staker = msg.sender;
        require(_balances[Staker] > 0, ": No tokens in staking");
        require(unstake_enable == true, ": Unstaking not enable");
        for(uint i = 0; i < _count; i++){           
            uint256 Staker_balance = _balances[Staker];
            uint256 tokenId = _tokensOfOwners[Staker][Staker_balance];
            IERC721(SanshiNFT).transferFrom(address(this), Staker, tokenId); //transfer the token 
            _balances[Staker]--; //decrease staker balance
        }
    }

    function set_SanshiNFT(address _SanshiNFT) external onlyOwner {
        SanshiNFT = _SanshiNFT;
    }

    function flip_unstake_enable() external onlyOwner {
        unstake_enable = !unstake_enable;
    }
}