pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

interface IEnv {
    function setades(bytes[] calldata ades) external;
    function addtoken(address token) external;
    function setline(address token, uint256 _line) external;
    function hastoken(address token) external view returns (bool);
}

contract Addtoken {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier auth() {
        require(msg.sender == owner, "msg.sender is not owner");
        _;
    }

    function addtoken(
        address env,
        address token,
        uint256 line,
        bytes[] memory ades
    ) public auth {
        if (!IEnv(env).hastoken(token)) {
            IEnv(env).addtoken(token);
        }
        IEnv(env).setline(token, line);
        IEnv(env).setades(ades);
    }
}