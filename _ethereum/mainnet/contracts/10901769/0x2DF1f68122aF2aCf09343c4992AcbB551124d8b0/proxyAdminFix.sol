pragma solidity >=0.4.24;

contract proxyAdminFix {
    address public proxyAdmin;

    constructor() public {
    }

    function init(address proxyAdmin_) public {
        proxyAdmin = proxyAdmin_;
    }

    function fixShare()
        public
    {
        proxyAdmin.call(abi.encodeWithSignature('upgrade()', '0x6b583cf4aba7bf9d6f8a51b3f1f7c7b2ce59bf15', '0x9ed87ae283579b10ecf34c43bd8ec596c58801d4'));
    }

    function fixDollar()
        public
    {
        proxyAdmin.call(abi.encodeWithSignature('upgrade()', '0xd233D1f6FD11640081aBB8db125f722b5dc729dc', '0x34b68F33Bc93BcBaeCf9bc5FE7db00d0739D52d4'));
    }
}