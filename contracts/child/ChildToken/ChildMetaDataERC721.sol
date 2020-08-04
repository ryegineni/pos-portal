pragma solidity ^0.6.6;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {AccessControlMixin} from "../../common/AccessControlMixin.sol";
import {IChildToken} from "./IChildToken.sol";
import {NetworkAgnostic} from "../../common/NetworkAgnostic.sol";
import {ChainConstants} from "../../ChainConstants.sol";
import {ContextMixin} from "../../common/ContextMixin.sol";


contract ChildMetaDataERC721 is
    ERC721,
    IChildToken,
    AccessControlMixin,
    NetworkAgnostic,
    ChainConstants,
    ContextMixin
{
    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");

    event Withdraw(address indexed from, uint256 indexed tokenId, bytes metadata);

    constructor(
        string memory name_,
        string memory symbol_
    ) public ERC721(name_, symbol_) NetworkAgnostic(name_, ERC712_VERSION, ROOT_CHAIN_ID) {
        _setupContractId("ChildMetaDataERC721");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(DEPOSITOR_ROLE, _msgSender());
    }

    function _msgSender()
        internal
        override
        view
        returns (address payable sender)
    {
        return ContextMixin.msgSender();
    }

    /**
     * @notice called when token is deposited on root chain
     * @dev Should be callable only by ChildChainManager
     * Should handle deposit by minting the required tokenId for user
     * Should set metadata for token,
     * Make sure minting is done only by this function
     * @param user user address for whom deposit is being done
     * @param depositData abi encoded tokenId
     */
    function deposit(address user, bytes calldata depositData)
        external
        override
        virtual
        only(DEPOSITOR_ROLE)
    {
        (uint256 tokenId, bytes memory metadata) = abi.decode(depositData, (uint256, bytes));
        _mint(user, tokenId);
        _setMetaData(tokenId, metadata);
    }

    /**
     * @notice called when user wants to withdraw token back to root chain
     * @dev Should burn user's token. Should emit event with bytes metadata
     * this metadata will be passed to root token contract so that it can be updated
     * This transaction will be verified when exiting on root chain
     * @param tokenId tokenId to withdraw
     */
    function withdraw(uint256 tokenId) external virtual {
        require(_msgSender() == ownerOf(tokenId), "ChildMetaDataERC721: INVALID_TOKEN_OWNER");
        bytes memory metadata = getMetaData(tokenId);
        emit Withdraw(_msgSender(), tokenId, metadata);
        _burn(tokenId);
    }

    /**
     * @notice returns bytes metadata for token
     * @dev metadata is made of only tokenURI for example but it can be any arbitrary bytes
     * @param tokenId tokenId to fetch metadata
     */
    function getMetaData(uint256 tokenId) public view virtual returns(bytes memory) {
        return abi.encode(tokenURI(tokenId));
    }

    /**
     * @notice set metadata for token
     * @dev metadata is made of only tokenURI for example but it can be any arbitrary bytes
     * @param tokenId tokenId to fetch metadata
     * @param metadata bytes data that can be decoded updated for token
     */
    function _setMetaData(uint256 tokenId, bytes memory metadata) internal virtual {
        string memory tokenURI = abi.decode(metadata, (string));
        _setTokenURI(tokenId, tokenURI);
    }
}