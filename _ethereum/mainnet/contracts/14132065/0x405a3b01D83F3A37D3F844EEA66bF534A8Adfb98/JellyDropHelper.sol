pragma solidity 0.8.6;

import "IERC20.sol";
import "IMerkleList.sol";
import "IJellyFactory.sol";
import "IJellyDrop.sol";
import "DocumentHelper.sol";

contract JellyDropHelper is DocumentHelper {
    struct TokenInfo {
        address addr;
        string name;
        string symbol;
        uint256 decimals;
    }

    struct AirdropInfo {
        address airdrop;
        string merkleURI;
        uint256 rewardsPaid;
        TokenInfo rewardToken;
        RewardInfo rewardInfo;
        Document[] documents;
    }

    address owner;
    IJellyFactory jellyFactory;
    bytes32 public constant AIRDROP_ID = keccak256("JELLY_DROP");

    constructor(
        address _jellyFactory
    )
    {
        owner = msg.sender;
        setContracts(_jellyFactory);
    }

    function setContracts(address _jellyFactory) public {
        require(msg.sender == owner);
        jellyFactory = IJellyFactory(_jellyFactory);
    }

    function getTokenInfo(address _address)
        public
        view
        returns (TokenInfo memory)
    {
        TokenInfo memory info;
        IERC20 token = IERC20(_address);

        info.addr = _address;
        info.name = token.name();
        info.symbol = token.symbol();
        info.decimals = token.decimals();

        return info;
    }


    function getAirdropInfo(address _airdropAddress)
        public
        view
        returns (AirdropInfo memory airdropInfo)
    {
        IJellyDrop airdrop = IJellyDrop(_airdropAddress);
        IMerkleList list = IMerkleList(airdrop.list());
        airdropInfo.airdrop = _airdropAddress;
        airdropInfo.merkleURI = list.currentMerkleURI();
        airdropInfo.rewardToken = getTokenInfo(airdrop.rewardsToken());
        airdropInfo.rewardsPaid = airdrop.rewardsPaid();
        airdropInfo.rewardInfo = airdrop.rewardInfo();
        airdropInfo.documents = getDocuments(_airdropAddress);
    }

    function getAirdrops() public view returns (AirdropInfo[] memory) {
        address[] memory contracts = jellyFactory.getContractsByTemplateId(AIRDROP_ID);
        uint256 size = contracts.length;
        AirdropInfo[] memory airdrops = new AirdropInfo[](size);

        for (uint256 i = 0; i < size; i++) {
            airdrops[i] = getAirdropInfo(contracts[i]);
        }
        return airdrops;
    }

}
