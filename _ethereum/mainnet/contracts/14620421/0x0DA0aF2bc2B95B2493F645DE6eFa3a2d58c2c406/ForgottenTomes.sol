//SPDX-License-Identifier: None
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                //
//                                                                                                                //
//      ___________                         __    __                  ___________                                 //
//      \_   _____/__________  ____   _____/  |__/  |_  ____   ____   \__    ___/___   _____   ____   ______      //
//       |    __)/  _ \_  __ \/ ___\ /  _ \   __\   __\/ __ \ /    \    |    | /  _ \ /     \_/ __ \ /  ___/      //
//       |     \(  <_> )  | \/ /_/  >  <_> )  |  |  | \  ___/|   |  \   |    |(  <_> )  Y Y  \  ___/ \___ \       //
//       \___  / \____/|__|  \___  / \____/|__|  |__|  \___  >___|  /   |____| \____/|__|_|  /\___  >____  >      //
//           \/             /_____/                        \/     \/                       \/     \/     \/       //
//                                                                                                                //
//                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract ForgottenTomes is ERC721A, Ownable {
    string public baseURI;
    bool public baseURILocked = false;
    bool public mintingLocked = false;

    constructor() ERC721A("Forgotten Tomes", "TOME") {}

    // @notice Mint a new Forgotten Tome.
    function mint() external onlyOwner {
        if (!mintingLocked) {
            _safeMint(msg.sender, 1);
        }
    }

    // @notice Prevents furthur minting. This is irreversible.
    function lockMinting() external onlyOwner {
        mintingLocked = true;
    }

    // @notice Update the baseURI.
    function setBaseURI(string calldata _uri) external onlyOwner {
        if (!baseURILocked) {
            baseURI = _uri;
        }
    }

    // @notice Prevents the baseURI from being changed. This is irreversible.
    function lockBaseURI() external onlyOwner {
        baseURILocked = true;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}