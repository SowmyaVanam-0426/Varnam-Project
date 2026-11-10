import { useMemo, useState } from "react";
import { Search, ShoppingBag, Plus, Menu, X, ArrowRight, Leaf } from "lucide-react";

const books = [
  { id: 1, title: "The Secret Garden", author: "Frances Hodgson Burnett", price: 399, cover: "sage", category: "Classics", note: "A timeless classic", initial: "S" },
  { id: 2, title: "Little Women", author: "Louisa May Alcott", price: 449, cover: "rose", category: "Classics", note: "A reader's favourite", initial: "L" },
  { id: 3, title: "Anne of Green Gables", author: "L. M. Montgomery", price: 379, cover: "ochre", category: "Fiction", note: "A countryside tale", initial: "A" },
  { id: 4, title: "Pride and Prejudice", author: "Jane Austen", price: 499, cover: "wine", category: "Classics", note: "A beloved romance", initial: "P" },
  { id: 5, title: "The Enchanted April", author: "Elizabeth von Arnim", price: 429, cover: "moss", category: "Fiction", note: "A little escape", initial: "E" },
  { id: 6, title: "A Room with a View", author: "E. M. Forster", price: 359, cover: "blue", category: "Fiction", note: "For wandering minds", initial: "R" },
  { id: 7, title: "Persuasion", author: "Jane Austen", price: 389, cover: "plum", category: "Classics", note: "Quietly unforgettable", initial: "P" },
  { id: 8, title: "The Wind in the Willows", author: "Kenneth Grahame", price: 419, cover: "forest", category: "Children", note: "A gentle adventure", initial: "W" }
];

function BookCover({ book }) {
  return (
    <div className={`book-cover ${book.cover}`} aria-label={`Decorative cover for ${book.title}`}>
      <span className="cover-top">BOOKNEST · COLLECTED STORIES</span>
      <span className="cover-ornament">✳</span>
      <strong>{book.title}</strong>
      <span className="cover-author">{book.author}</span>
      <span className="cover-bottom">❧</span>
    </div>
  );
}

export default function App() {
  const [cart, setCart] = useState([]);
  const [searchOpen, setSearchOpen] = useState(false);
  const [search, setSearch] = useState("");
  const [menuOpen, setMenuOpen] = useState(false);
  const [category, setCategory] = useState("All books");

  const filteredBooks = useMemo(() => books.filter((book) => {
    const matchesSearch = `${book.title} ${book.author}`.toLowerCase().includes(search.toLowerCase());
    const matchesCategory = category === "All books" || book.category === category;
    return matchesSearch && matchesCategory;
  }), [search, category]);

  const addToCart = (book) => setCart((items) => [...items, book]);
  const cartTotal = cart.reduce((sum, book) => sum + book.price, 0);

  return (
    <div className="site-shell">
      <div className="announcement">A little world of stories, delivered to your doorstep <span>✳</span></div>

      <header className="navbar">
        <a className="brand" href="#home" aria-label="BookNest home">
          <span className="brand-mark">❧</span>
          <span><strong>BookNest</strong><small>THE CURATED BOOKSHOP</small></span>
        </a>

        <button className="mobile-menu icon-button" onClick={() => setMenuOpen(!menuOpen)} aria-label="Toggle navigation">
          {menuOpen ? <X /> : <Menu />}
        </button>

        <nav className={menuOpen ? "nav-links open" : "nav-links"}>
          <a href="#home" onClick={() => setMenuOpen(false)}>Home</a>
          <a href="#collection" onClick={() => setMenuOpen(false)}>Our collection</a>
          <a href="#story" onClick={() => setMenuOpen(false)}>Our story</a>
        </nav>

        <div className="nav-actions">
          <button className="icon-button" aria-label="Search books" onClick={() => setSearchOpen(!searchOpen)}><Search size={19} /></button>
          <button className="bag-button" aria-label={`Shopping bag with ${cart.length} items`} onClick={() => document.getElementById("cart-summary").scrollIntoView({ behavior: "smooth" })}>
            <ShoppingBag size={18} /><span>{cart.length}</span>
          </button>
        </div>
      </header>

      {searchOpen && (
        <div className="search-strip">
          <Search size={17} />
          <input autoFocus placeholder="Find a story, author or old favourite..." value={search} onChange={(e) => setSearch(e.target.value)} />
          <button onClick={() => { setSearch(""); setSearchOpen(false); }} aria-label="Close search"><X size={17} /></button>
        </div>
      )}

      <main>
        <section className="hero" id="home">
          <div className="hero-copy">
            <div className="eyebrow"><Leaf size={13} /> A BOOKSHOP FOR THE SOUL</div>
            <h1>Stories worth<br />staying <em>for.</em></h1>
            <p>For slow mornings, rainy afternoons and evenings lost between the pages of a good book. Find your next favourite story here.</p>
            <a className="primary-link" href="#collection">Explore the collection <ArrowRight size={16} /></a>
            <div className="hero-note"><span>✳</span> Carefully chosen. Thoughtfully delivered.</div>
          </div>

          <div className="hero-visual">
            <div className="hero-art">
              <div className="art-corner">✿</div>
              <div className="art-sun">☼</div>
              <div className="art-title">A quiet place<br />for curious minds</div>
              <div className="art-flora">❧ &nbsp; ✿ &nbsp; ❧</div>
              <div className="art-edition">EST. WITH LOVE · 2026</div>
            </div>
            <span className="visual-caption">A SHELF OF YOUR VERY OWN</span>
          </div>
          <div className="hero-side-note">ISSUE NO. 01 &nbsp; · &nbsp; THE SLOW LIVING EDIT</div>
        </section>

        <section className="intro-band">
          <span>“</span>
          <p>There is no friend as loyal as a book.</p>
          <small>— ERNEST HEMINGWAY</small>
        </section>

        <section className="collection section-wrap" id="collection">
          <div className="section-heading">
            <div><div className="eyebrow">THE BOOKSHELF</div><h2>Chosen with <em>care.</em></h2></div>
            <p>A small collection of stories<br />we think you'll want to keep.</p>
          </div>

          <div className="collection-tools">
            <div className="category-tabs">
              {["All books", "Classics", "Fiction", "Children"].map((item) => (
                <button key={item} className={category === item ? "active" : ""} onClick={() => setCategory(item)}>{item}</button>
              ))}
            </div>
            <span>{filteredBooks.length} BOOKS TO DISCOVER</span>
          </div>

          <div className="book-grid">
            {filteredBooks.map((book) => (
              <article className="book-card" key={book.id}>
                <div className="cover-wrap"><BookCover book={book} /><span className="book-ribbon">{book.note}</span></div>
                <div className="book-info">
                  <div className="book-category">{book.category.toUpperCase()}</div>
                  <h3>{book.title}</h3>
                  <p>{book.author}</p>
                  <div className="book-bottom">
                    <strong>₹{book.price}</strong>
                    <button onClick={() => addToCart(book)} aria-label={`Add ${book.title} to bag`}><Plus size={16} /> Add to bag</button>
                  </div>
                </div>
              </article>
            ))}
            {filteredBooks.length === 0 && <p className="empty-state">No stories found. Try another title or author.</p>}
          </div>
        </section>

        <section className="story-section" id="story">
          <div className="story-flower">❀</div>
          <div className="eyebrow">A NOTE FROM OUR BOOKSHOP</div>
          <h2>Not just books.<br /><em>A little escape.</em></h2>
          <p>We believe in dog-eared pages, handwritten notes and the particular magic of finding a story at just the right time. BookNest is a small, thoughtful corner of the world for readers who like to linger.</p>
          <a href="#collection">Find your next read <ArrowRight size={15} /></a>
        </section>

        <section className="cart-summary section-wrap" id="cart-summary">
          <div><div className="eyebrow">YOUR LITTLE BOOK PILE</div><h2>A bag full of <em>stories.</em></h2></div>
          <div className="cart-detail">
            <span>{cart.length} {cart.length === 1 ? "book" : "books"} in your bag</span>
            <strong>₹{cartTotal}</strong>
            <small>{cart.length ? "Your selections are waiting for you." : "Add a book from the collection to begin."}</small>
          </div>
        </section>
      </main>

      <footer className="footer">
        <div className="footer-brand">❧ <strong>BookNest</strong></div>
        <p>Made for the love of stories.</p>
        <span>© 2026 BOOKNEST · THE CURATED BOOKSHOP</span>
      </footer>
    </div>
  );
}
