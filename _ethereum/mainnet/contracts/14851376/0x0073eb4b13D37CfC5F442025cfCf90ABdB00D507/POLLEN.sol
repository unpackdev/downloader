// SPDX-License-Identifier: MIT
//  ____    _____   __       __       ____    __  __
// /\  _`\ /\  __`\/\ \     /\ \     /\  _`\ /\ \/\ \
// \ \ \L\ \ \ \/\ \ \ \    \ \ \    \ \ \L\_\ \ `\\ \
//  \ \ ,__/\ \ \ \ \ \ \  __\ \ \  __\ \  _\L\ \ , ` \
//   \ \ \/  \ \ \_\ \ \ \L\ \\ \ \L\ \\ \ \L\ \ \ \`\ \
//    \ \_\   \ \_____\ \____/ \ \____/ \ \____/\ \_\ \_\
//     \/_/    \/_____/\/___/   \/___/   \/___/  \/_/\/_/
//
// $POLLEN token will enable holders to purchase various assets in the Coin Plants ecosystem, including but not limited too: exclusive limited release merch, digital items, events, and even future generations of Coin Plants.

pragma solidity ^0.8.7;
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC20.sol";

contract POLLENToken is ERC20("Pollen", "POLLEN"), Ownable, Pausable {
    constructor() {
        _mint(0xc4E2F2132971ad462bc4e5eC3B068700B465FFFe, 30000 * 10**18); // Coin Plants NFT Treasury Wallet (ERC20)
        _mint(0xe8796456414FfeB393AA3D943976c3B4231Ff370, 50000 * 10**18); // Josiah's Wallet Address (ERC20)
        _mint(0xD801c20cfE544886a348192b0D95417C095Fef06, 20000 * 10**18); // Nina’s Wallet Address (ERC20)

        _mint(msg.sender, 776900000 * 10**18);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(!paused(), "TRANSFER_PAUSED");
        super._beforeTokenTransfer(from, to, amount);
    }

    function pause() external onlyOwner {
        require(!paused(), "ALREADY_PAUSED");
        _pause();
    }

    function unpause() external onlyOwner {
        require(paused(), "ALREADY_UNPAUSED");
        _unpause();
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }
}
