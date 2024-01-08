import "ERC1967Proxy.sol";

contract UUPSProxy is ERC1967Proxy {
    constructor(address _logic, bytes memory _data) ERC1967Proxy(_logic, _data) payable {}
}
