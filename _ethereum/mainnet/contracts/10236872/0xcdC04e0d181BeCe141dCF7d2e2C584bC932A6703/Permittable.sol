pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import "./ZoraTypes.sol";

contract Permittable {

    /* ============ Variables ============ */

    bytes32 public DOMAIN_SEPARATOR;

    mapping (address => uint256) public permitNonces;

    /* ============ Constants ============ */

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /* ============ Constructor ============ */

    constructor(
        string memory name,
        string memory version
    )
        public
    {
        DOMAIN_SEPARATOR = initDomainSeparator(name, version);
    }

    /**
     * @dev Initializes EIP712 DOMAIN_SEPARATOR based on the current contract and chain ID.
     */
    function initDomainSeparator(
        string memory name,
        string memory version
    )
        private
        returns (bytes32)
    {
        uint256 chainID;
        /* solium-disable-next-line */
        assembly {
            chainID := chainid()
        }

        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainID,
                address(this)
            )
        );
    }

    /**
    * @dev Approve by signature.
    *
    * Adapted from Uniswap's UniswapV2ERC20 and MakerDAO's Dai contracts:
    * https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol
    * https://github.com/makerdao/dss/blob/master/src/dai.sol
    */
    function _permit(
        ZoraTypes.Permit memory permit
    )
        public
        virtual
    {

        require(
            permit.deadline == 0 || permit.deadline >= block.timestamp,
            "Permittable: Permit expired"
        );

        require(
            permit.spender != address(0),
            "Permittable: spender cannot be 0x0"
        );

        require(
            permit.value > 0,
            "Permittable: approval value must be greater than 0"
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                    PERMIT_TYPEHASH,
                    permit.owner,
                    permit.spender,
                    permit.value,
                    permitNonces[permit.owner]++,
                    permit.deadline
                )
            )
        ));

        address recoveredAddress = ecrecover(digest, permit.v, permit.r, permit.s);

        require(
            recoveredAddress != address(0) && permit.owner == recoveredAddress,
            "DropToken: Signature invalid"
        );

    }

}