---
layout: page
title: Čas 5 - Normalizacija
---

### Materijali

- [Uvod]({{ site.baseurl }}{% link resources/projbp/05_normalizacija.pdf %})
- [Zadaci za vežbanje]({{ site.baseurl }}{% link resources/projbp/05_norm_vezbanje.pdf %})

### Neke napomene

- U uvodnoj prezentaciji postoji greška u zapisu svojstva tranzitivnosti
  za funkcionalne zavisnosti. Trebalo bi da piše X ⟶ Y ∧ Y ⟶ Z ⇒ X ⟶ Z.
- Prilikom svođenja na treću normalnu formu u uvodnom primeru, izvršena
  je dekompozicija po funkcionalnoj zavisnosti *ime artikla ⟶ sekcija*, 
  ali je nakon toga *ime artikla* zamenjeno sa *sifra artikla*. Ovim postupkom
  je izgubljena prethodna funkcionalna zavisnost. Iako možda ima više smisla
  da šifra, a ne ime, određuje sekciju, da u početku nije bilo
  izgubljene funkcionalne zavisnosti *ime artikla ⟶ sekcija*, uopšte ne bi
  ni bilo izvršeno razbijanje relacije artikala, jer nakon dovođenja u 2NF, relacija
  bi bila i u 3NF.
