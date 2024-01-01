pragma solidity >=0.8.0;

interface ITopic {

    event SetTopic(
        uint256 indexed id,
        string name,
        uint256 startTime,
        uint256 totalSupply
    );

    event SetOpinion(
        uint256 indexed id,
        string name,
        uint256 startTime,
        uint256 totalSupply,
        uint256 parentId
    );

    event BuyPower(
        address indexed sender,
        uint256 id,
        uint256 price,
        uint256 costIn,
        uint256 amount,
        uint256 burned,
        uint256 fee
    );

    event SellPower(
        address indexed sender,
        uint256 id,
        uint256 price,
        uint256 gainOut,
        uint256 amount,
        uint256 burned,
        uint256 fee
    );

    event BuyVote(
        address indexed sender,
        uint256 id,
        uint256 ethPrice,
        uint256 price,
        uint256 powerIn,
        uint256 amount,
        uint256 burned,
        uint256 fee
    );

    event SellVote(
        address indexed sender,
        uint256 id,
        uint256 ethPrice,
        uint256 price,
        uint256 powerOut,
        uint256 amount,
        uint256 burned,
        uint256 fee
    );

    event Transfer(
        uint256 indexed id,
        address indexed from,
        address indexed to,
        uint256 amount);

    event Burn(
        uint256 indexed id,
        address indexed from,
        uint256 amount);

    function decimals() external view returns (uint8);

    function transfer(
        uint256 id,
        address to,
        uint256 amount
    ) external;

    function burn(
        uint256 id,
        uint256 amount
    ) external;

    function getLiquidity(uint256 id) external view returns (uint256 liquidityPower, uint256 liquidity);

    function topicPrice(uint256 id) external view returns (uint256);

    function opinionPrice(uint256 id) external view returns (uint256);

    function buyTopicPower(uint256 id, uint256 cost) external view returns (uint256);

    function sellTopicGain(uint256 id, uint256 amount) external view returns (uint256);

    function buyPower(uint256 id, uint256 amountOutMin) external payable;

    function sellPower(uint256 id, uint256 amount, uint256 amountOutMin) external;

    function buyOpinionVote(uint256 id, uint256 cost) external view returns (uint256);

    function sellOpinionGain(uint256 id, uint256 amount) external view returns (uint256);

    function buyVote(uint256 id, uint256 amountOutMin, uint256 cost) external;

    function sellVote(uint256 id, uint256 amount, uint256 amountOutMin) external;

    function buyVoteInETH(uint256 id, uint256 amountOutMin) external payable;

    function sellVote2ETH(uint256 id, uint256 amount, uint256 amountOutMin) external;
}
