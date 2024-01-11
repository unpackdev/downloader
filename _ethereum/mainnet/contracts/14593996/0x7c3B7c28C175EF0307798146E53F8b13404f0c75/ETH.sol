import "./ERC20.sol";

contract ETH is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000000000 ether);
    }
}
