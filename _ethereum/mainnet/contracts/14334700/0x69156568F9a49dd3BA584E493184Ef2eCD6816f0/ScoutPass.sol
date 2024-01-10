// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./BasePass.sol";
import "./IRenderer.sol";
import "./OpenSeaMetadata.sol";
import "./Sprites.sol";

contract ScoutPass is BasePass {
    IRenderer public renderer;
    string private _symbol;

    constructor(IUtilityERC20 _token, IRenderer _renderer)
        BasePass(
            _token,
            200 ether,
            "Scout Pass"
        )
    {
        _symbol = "SCOUTPASS";
        renderer = _renderer;
    }

    function extensionKey() public override pure returns (string memory) {
        return "metaversePass";
    }
    
    function adminSetRenderer(IRenderer _renderer) external onlyAdmin {
        renderer = _renderer;
    }

    function adminSetSymbol(string memory sym) external onlyAdmin {
        _symbol = sym;
    }

    function metadata() public virtual view override returns (OpenSeaMetadata memory) {
        bytes[] memory passSprite = new bytes[](1);
        passSprite[0] = MiscSprites.passSprite();
        string memory sprite = renderer.render(passSprite);

        return OpenSeaMetadata({
            svg: sprite,
            name: "Scout Pass",
            description: "The Scout Pass is the key to unlock perks in the Chain Scouts ecosystem",
            backgroundColor: 0,
            attributes: new Attribute[](0)
        });
    }

    function symbol() public virtual view override returns (string memory) {
        return _symbol;
    }
}
