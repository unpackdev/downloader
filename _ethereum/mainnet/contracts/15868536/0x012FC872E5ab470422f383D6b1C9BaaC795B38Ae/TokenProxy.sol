//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity 0.8.16;

import "./AutoProxy.sol";
import "./ConsiderationConstants.sol";
import "./IERC721Metadata.sol";

contract LicenseProxy is AutoProxy {
    constructor() AutoProxy(CONFIG, CONFIG_LICENSE_ERC1155_IMPL_KEY, "") {} // solhint-disable-line no-empty-blocks
}

contract ERC721DerivativeProxy is AutoProxy {
    constructor() AutoProxy(CONFIG, CONFIG_DERIVATIVE_ERC721_IMPL_KEY, "") {} // solhint-disable-line no-empty-blocks
}

contract ERC1155DerivativeProxy is AutoProxy {
    constructor() AutoProxy(CONFIG, CONFIG_DERIVATIVE_ERC1155_IMPL_KEY, "") {} // solhint-disable-line no-empty-blocks
}
