// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IERC6551Account.sol";
import "./IERC6551Registry.sol";
import "./IMOPNGovernance.sol";
import "./IMOPN.sol";
import "./ERC1155.sol";
import "./Multicall.sol";
import "./Ownable.sol";

/*
.___  ___.   ______   .______   .__   __. 
|   \/   |  /  __  \  |   _  \  |  \ |  | 
|  \  /  | |  |  |  | |  |_)  | |   \|  | 
|  |\/|  | |  |  |  | |   ___/  |  . `  | 
|  |  |  | |  `--'  | |  |      |  |\   | 
|__|  |__|  \______/  | _|      |__| \__| 
*/
contract MOPNBomb is ERC1155, Multicall, Ownable {
    string public name;
    string public symbol;

    IMOPNGovernance governance;

    mapping(uint256 => string) private _uris;

    modifier onlyMOPN() {
        require(
            msg.sender == governance.mopnContract() ||
                msg.sender == governance.auctionHouseContract(),
            "not allowed"
        );
        _;
    }

    constructor(address governance_) ERC1155("") {
        name = "MOPN Bomb";
        symbol = "MOPNBOMB";
        governance = IMOPNGovernance(governance_);
    }

    /**
     * @notice setURI is used to set the URI corresponding to the tokenId
     * @param tokenId_ token id
     * @param uri_ metadata uri corresponding to the token
     */
    function setURI(uint256 tokenId_, string calldata uri_) external onlyOwner {
        _uris[tokenId_] = uri_;
        emit URI(uri_, tokenId_);
    }

    /**
     * @notice uri is used to get the URI corresponding to the tokenId
     * @param tokenId_ token id
     * @return metadata uri corresponding to the token
     */
    function uri(
        uint256 tokenId_
    ) public view virtual override returns (string memory) {
        return _uris[tokenId_];
    }

    function mint(address to, uint256 id, uint256 amount) public onlyMOPN {
        _mint(to, id, amount, "");
    }

    function burn(address from, uint256 id, uint256 amount) public onlyMOPN {
        _burn(from, id, amount);
    }
}
