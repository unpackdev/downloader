pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IBurnable.sol";


contract ObortechToken is ERC20, Ownable, IBurnable {
    address private tokenDistributionContract;

    constructor (string memory name_, string memory symbol_) public ERC20(name_, symbol_) {
        _mint(_msgSender(), 300_000_000 * 10 ** 18);
    }

    function getTokenDistributionContract() external view returns (address) {
        return tokenDistributionContract;
    }

    function setTokenDistributionContract(address _tokenDistributionContract) external onlyOwner {
        tokenDistributionContract = _tokenDistributionContract;
    }

    function burn(uint256 amount) external override {
       require(_msgSender() == tokenDistributionContract, "No rights");
       _burn(_msgSender(), amount);
    }
}
