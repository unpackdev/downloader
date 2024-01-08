import "./IERC721Enumerable.sol";

pragma solidity ^0.8.6;

contract MultivisaRewardSplitter {
    IERC721Enumerable multivisa;
    mapping(uint256 => uint256) private claimedReward;
    uint256 totalRewardPerToken;

    constructor (IERC721Enumerable _multivisa){
        multivisa = _multivisa;
    }

    receive() external payable {
        uint256 totalMultivisa = multivisa.totalSupply();
        uint256 newAmountPerToken = msg.value / totalMultivisa;
        totalRewardPerToken += newAmountPerToken;
    }

    function claimAll() public {
        uint256 amount = 0;
        uint256 numTokens = multivisa.balanceOf(msg.sender);

        for(uint256 i = 0; i < numTokens; i++) {
            uint256 tokenID = multivisa.tokenOfOwnerByIndex(msg.sender, i);
            uint256 difference = totalRewardPerToken - claimedReward[tokenID];
            // Your re-entrancy holds no power here
            claimedReward[tokenID] += difference;
            amount += difference;
        }

        require(amount > 0, "Nothing to Claim");
        require(payable(msg.sender).send(amount));
    }

    function claimID(uint256 _tokenID) public {
        require(IERC721(multivisa).ownerOf(_tokenID) == msg.sender,  "You do not own the Multivisa with specified ID");
        uint256 difference = totalRewardPerToken - claimedReward[_tokenID];
        // Your re-entrancy holds no power here
        claimedReward[_tokenID] += difference;
        require(difference > 0, "Nothing to Claim");
        require(payable(msg.sender).send(difference));
    }

    // View functions

    // Returns total ETH reward amount for a user accross all owner Multivisas
    function claimableBalance(address _owner) public view returns (uint256) {
        uint256 balance = 0;
        uint256 numTokens = multivisa.balanceOf(_owner);

        for(uint256 i = 0; i < numTokens; i++) {
            balance += ethRewardForID(multivisa.tokenOfOwnerByIndex(_owner, i));
        }

        return balance;
    }

    // Returns ETH reward for specified tokenID in gwei, divide result by 10e18 for ETH value
    function ethRewardForID(uint256 tokenId) public view returns (uint256) {
        return totalRewardPerToken - claimedReward[tokenId];
    }
}