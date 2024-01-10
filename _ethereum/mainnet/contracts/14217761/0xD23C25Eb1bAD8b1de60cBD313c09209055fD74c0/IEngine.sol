//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC165.sol";
import "./IShellFramework.sol";

// Required interface for framework engines
// interfaceId = 0x0b1d171c
interface IEngine is IERC165 {
    // Get the name for this engine
    function name() external pure returns (string memory);

    // Called by the framework to resolve a response for tokenURI method
    function getTokenURI(IShellFramework collection, uint256 tokenId)
        external
        view
        returns (string memory);

    // Called by the framework to resolve a response for royaltyInfo method
    function getRoyaltyInfo(
        IShellFramework collection,
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);

    // Called by the framework during a transfer, including mints (from=0) and
    // burns (to=0). Cannot break transfer even in the case of reverting, as the
    // collection will wrap the downstream call in a try/catch
    // collection = msg.sender
    function beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external;

    // Called by the framework whenever an engine is set on a fork, including
    // the collection (fork id = 0). Can be used by engine developers to prevent
    // an engine from being installed in a collection or non-canonical fork if
    // desired
    // collection = msg.sender
    function afterEngineSet(uint256 forkId) external;
}
