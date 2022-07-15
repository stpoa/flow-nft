import NonFungibleToken from "./NonFungibleToken.cdc";
import MetadataViews from "./MetadataViews.cdc";


pub contract CrazyCats: NonFungibleToken {
  // Consts
  pub let CollectionStoragePath: StoragePath
  pub let CollectionPublicPath: PublicPath

  // Vars
  pub var totalSupply: UInt64;

  // Events
  pub event ContractInitialized()
  pub event Withdraw(id: UInt64, from: Address?)
  pub event Deposit(id: UInt64, to: Address?)
 
  // Resource interfaces
  pub resource interface CrazyCatsCollectionPublic {
    pub fun deposit(token: @NonFungibleToken.NFT)
    pub fun getIDs(): [UInt64]
    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
  }

  // Resources
  pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
    pub let id: UInt64
    pub let name: String
    pub let description: String
    pub let thumbnail: String

    init(
      id: UInt64,
      name: String,
      description: String,
      thumbnail: String
    ) {
        self.id = id
        self.name = name
        self.description =description 
        self.thumbnail = thumbnail

        CrazyCats.totalSupply = CrazyCats.totalSupply + (1 as UInt64)
    }

    pub fun getViews(): [Type] {
      return [
        Type<MetadataViews.Display>()
      ]
    }

    pub fun resolveView(_ view: Type): AnyStruct? {
      switch view {
        case Type<MetadataViews.Display>():
          return MetadataViews.Display(
            name: self.name,
            description: self.description,
            thumbnail: MetadataViews.HTTPFile(
              url: self.thumbnail
            )
          )
          default:
            return nil
      }
    }
  }
 
  pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, CrazyCatsCollectionPublic, MetadataViews.ResolverCollection {
    pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

    pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
      let token <- self.ownedNFTs.remove(key: withdrawID) ??
        panic("This collection doesn't contain an NFT with that id")

      emit Withdraw(id: token.id, from: self.owner?.address)
      
      return <- token
    }

    pub fun deposit(token: @NonFungibleToken.NFT) {
      let token <- token as! @CrazyCats.NFT
      let id = token.id
      let oldToken <- self.ownedNFTs[id] <- token

      emit Deposit(id: id, to: self.owner?.address)

      destroy oldToken
    }
    
    pub fun getIDs(): [UInt64] {
      return self.ownedNFTs.keys
    }

    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
      return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
    }

    pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
      let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
      let CrazyCats = nft as! &CrazyCats.NFT
      return CrazyCats as &AnyResource{MetadataViews.Resolver}
    }


    init() {
      self.ownedNFTs <- {}
    }
  
    destroy () {
      destroy self.ownedNFTs
    }
  }

  pub fun mintNFT(
    recipient: &{NonFungibleToken.CollectionPublic},
    name: String,
    description: String,
    thumbnail: String,
  ) {
    let newNFT <- create NFT(
      id: CrazyCats.totalSupply,
      name: name,
      description: description,
      thumbnail: thumbnail,
    )

    recipient.deposit(token: <- newNFT)

    CrazyCats.totalSupply = CrazyCats.totalSupply + UInt64(1)
  } 

  init() {
    self.totalSupply = 0
    self.CollectionStoragePath = /storage/CrazyCatsCollection
    self.CollectionPublicPath = /public/CrazyCatsCollection

    let collection <- create Collection()
    self.account.save(<- collection, to: self.CollectionStoragePath)

    self.account.link<&CrazyCats.Collection{NonFungibleToken.CollectionPublic, CrazyCats.CrazyCatsCollectionPublic}>(
      self.CollectionPublicPath,
      target: self.CollectionStoragePath,
    )

    emit ContractInitialized()
  }

    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection();
    }
}
