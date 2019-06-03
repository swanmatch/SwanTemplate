# SwanTemplate
Ruby on Rails complete scaffold template with bootstrap and material design.
You can use various additional functions just by scaffold.

## usage

```sh
git clone https://github.com/swanmatch/SwanTemplate
rails new BootstrapTest -d mysql -T -m SwanTemplate/main.rb
# example 
rails g swaffold author name
rails g swaffold genre name
rails g swaffold book title author:references genre:references overview:text 
rails db:migrate
```


## Additionnal Functions

### Bootstrap or MaterialDesign

You can choice design frame work.
```
      option  Please Choise use design frame work
          1)  Bootstrap
          2)  Material
      choose  Enter your selection: _
```
Simple form's configration and default _form.html.erb files are generated by your choice.

This is twitter bootstrap sample.

![bootstrap](https://raw.githubusercontent.com/swanmatch/images/master/SwanTemplate/swaffold.png)

This is material design sample.

![material design](https://raw.githubusercontent.com/swanmatch/images/master/SwanTemplate/material.png)


#### For bootstrap only, you can use lavish

1. Visit to www.lavishbootstrap.com
2. Provide an image.
3. copy the finished sass into a `.app/assets/stylesheets/_custom_variables.scss`

Example this image.

![フシギダネ](https://www.pokemon.jp/zukan/images/l/ff08ec6198db300abc91e69605469427.png)


Genarated page is this.

![lavish](https://raw.githubusercontent.com/swanmatch/images/master/SwanTemplate/fushigidane.png)


### Search sub class and form in index

Auto create search subclass in model.

They are include ActiveModel::Base.

And search form append in top of index pages.

You can search string(verchar) and text with LIKE,
integer, date with min..max,
references with IN by select2 multiple select


### Select2

references columns are auto apply select2.

you can like search relation sip table in edit page.

index pages are searchable by multiple select.


### Bootstrap Datepicker

Date type columns can input by bootstrap datepicker.


### Kaminari pagenation

Append pagination helper,
when search result count over 25.


### Logical Delete

Migration auto add "deleated_at" column.

Provide methods are
* logical_delete!
  insert Time.now to deleated_at column. 
* active
  where(deleated_at: nil)
* active?
* deleted
* deleted?

Scaffold delete method,
use logical_delete.

Scaffolded index page,
only show active columns.
and references select box too.


### Lock version

migration auto add "lock_version" column.

they hidden in edit pages.

added strong parametars.


### ERD and annnotate

after `rake db:migration`,
auto create Entity Relationsip Diagram pdf.

pleace install graphviz.

graphviz install guide.

https://voormedia.github.io/rails-erd/install.html

scheme infomation output to model as comment.

example
```ruby
# coding: utf-8
# == Schema Information
#
# Table name: books
#
#  id           :integer          not null, primary key
#  title        :string(255)
#  author_id    :integer
#  genre_id     :integer
#  overview     :text(65535)
#  lock_version :integer          default(0), not null
#  created_by   :integer
#  updated_by   :integer
#  deleted_by   :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  deleted_at   :datetime
```

### i18n genarator

Auto translate and create i18n.yml after migration.


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
