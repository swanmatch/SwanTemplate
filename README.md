# SwanTemplate
Ruby on Rails complete template with bootstrap and material design.
# SwanTemplate
Ruby on Rails complete scaffold template with bootstrap and material design.
You can use various additional functions just by scaffold.

## usage

```sh
git clone https://github.com/swanmatch/SwanTemplate
rails new BootstrapTest -d mysql -T -m SwanTemplate/main.rb
# example 
rails g scaffold author name
rails g scaffold genre name
rails g scaffold book title author:references genre:references overview:text 
```

## Additionnal Functions

### Bootstrap or MaterialDesign

#### For bootstrap only, you can use lavish

1. Visit to www.lavishbootstrap.com
2. Provide an image.
3. copy the finished sass into a `.app/assets/stylesheets/_custom_variables.scss`


### Search sub class and form in index

in model auto create search subclass.

they are include ActiveModel::Base.

search form append in top of index pages.

You can search string(verchar) and text with LIKE,
integer, date with from..to.


### Kaminari pagenation

append pagination helper,
when search result count over 20.


### Logical Delete

migration auto add "deleated_at" column.

Provide method
* logical_delete!
  insert Time.now to deleated_at column. 
* active
  where(deleated_at: nil)
* active?
* deleted
* deleted?

scaffold delete method,
use logical_delete.

Scaffolded index page,
only show active columns.
and references select box too.


### Select2

references columns are auto apply select2.

you can like search relation sip table in edit page.

index pages are searchable by multiple select.


### Bootstrap Datepicker

### ERD and annnotate

after `rake db:migration`,
auto create Entity Relationsip Diagram pdf.

pleace install graphviz, before `rails new`.

how to install graphviz.

https://voormedia.github.io/rails-erd/install.html


### Lock version

migration auto add "lock_version" column.

they are hidden in edit pages.


## Suppurts

I was test only ubuntu, mysql, ruby2.4 and rails 5.1.
Others may go well.


```
   ###################################################################
  ##                                                                 ##
  ##  Please enjoy your trip of the Limited Express Train on Rails!  ##
  ##                                                                 ##
   ###################################################################
      _Ｏ
  〈_〉
  ＿
 ||ｎｎ ─┐    y─────────────────、,─────────────────、_______
(￣￣￣|囗|   |日　口口口口口口口口| |口口口口口口口口口口| |ロ ロ|
[三三五Ｌ_」__|＿＿＿＿＿＿＿＿＿＿|_|＿＿＿＿＿＿＿＿＿＿|_|_____凵
∠7◎◎◎=◎~~~  ◎=◎     ◎=◎  ~  ◎=◎       ◎=◎ ~ ◎=◎
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=
