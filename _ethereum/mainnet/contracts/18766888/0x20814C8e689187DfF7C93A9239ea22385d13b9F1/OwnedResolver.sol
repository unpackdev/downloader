pragma solidity >=0.8.4;
import "./Ownable.sol";
import "./ABIResolver.sol";
import "./AddrResolver.sol";
import "./ContentHashResolver.sol";
import "./DNSResolver.sol";
import "./InterfaceResolver.sol";
import "./NameResolver.sol";
import "./PubkeyResolver.sol";
import "./TextResolver.sol";
import "./ExtendedResolver.sol";

/**
 * A simple resolver anyone can use; only allows the owner of a node to set its
 * address.
 */
contract OwnedResolver is
    Ownable,
    ABIResolver,
    AddrResolver,
    ContentHashResolver,
    DNSResolver,
    InterfaceResolver,
    NameResolver,
    PubkeyResolver,
    TextResolver,
    ExtendedResolver
{
    function isAuthorised(bytes32) internal view override returns (bool) {
        return msg.sender == owner();
    }

    function supportsInterface(
        bytes4 interfaceID
    )
        public
        view
        virtual
        override(
            ABIResolver,
            AddrResolver,
            ContentHashResolver,
            DNSResolver,
            InterfaceResolver,
            NameResolver,
            PubkeyResolver,
            TextResolver
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceID);
    }
}
