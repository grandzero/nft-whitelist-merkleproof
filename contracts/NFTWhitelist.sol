// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFTWhitelist is ERC721Enumerable, Pausable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    uint256 public maxSupply = 5555;
    uint256 public mintedTotal;
    uint256 public whitelistMaxSupply = 1000;
    Counters.Counter private _tokenIdCounter;
    uint256 public publicPrice = 1000000000000000000;
    uint256 public constant whitelistPrice = 750000000000000000;
    bytes32 public whitelistRoot;
    uint256 public constant wlMaxMintAmount = 2;
    mapping(address => bool) public whitelistClaimed;

    constructor() ERC721("NFTWhitelist", "NFTWL") {}

    enum SaleStatus {
        Pending,
        WhitelistSale,
        PublicSale,
        Ended
    }

    SaleStatus public currentStatus;

    function setWhitelistRoot(bytes32 _root) external onlyOwner {
        whitelistRoot = _root;
    }

    modifier isWhitelistSale() {
        require(
            currentStatus == SaleStatus.WhitelistSale,
            "Whitelist Sale is not active"
        );
        _;
    }

    function verifyWhitelist(address wlOwner, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                proof,
                whitelistRoot,
                keccak256(abi.encodePacked(wlOwner))
            );
    }

    function setStatus(uint256 _status) external onlyOwner {
        currentStatus = SaleStatus(_status);
    }

    function whitelistMint(bytes32[] memory proof, uint256 _amount)
        external
        payable
        isWhitelistSale
        whenNotPaused
    {
        require(
            _amount > 0 && mintedTotal + _amount <= maxSupply,
            "NFTWhitelist : Can't mint that amount"
        );
        require(
            _amount > 0 && mintedTotal + _amount <= whitelistMaxSupply,
            "NFTWhitelist : Can't mint that amount"
        );
        require(
            _amount <= wlMaxMintAmount,
            "NFTWhitelist: You can't mint more then 2"
        );
        require(
            verifyWhitelist(msg.sender, proof),
            "NFTWhitelist : This address is not whitelisted"
        );
        require(
            msg.value >= _amount * whitelistPrice,
            "NFTWhitelist : Not enough funds"
        );
        require(
            !whitelistClaimed[msg.sender],
            "NFTWhitelist : You already claimed your whitelist spot"
        );
        require(!paused(), "NFTWhitelist: Contract is paused");
        for (uint256 i = 0; i < _amount; i++) {
            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());
        }
        whitelistClaimed[msg.sender] = true;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "https://ipfs.io/ipfs/bafybeidr6bwwxytqwgpcvhnenyzcnxl2byg7pcqwbpydhralmy5sjfcs4q/",
                    tokenId.toString()
                )
            );
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
