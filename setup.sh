#!/bin/bash

# SETUP GO
rm -rf server client
mkdir server
cd server
read -p "Input your github-user/project-name: " project

go mod init "github.com/$project"
touch main.go
echo "package main

import (
  \"log\"
  \"os\"

  \"github.com/gofiber/fiber/v2\"
  \"github.com/joho/godotenv\"
  \"github.com/$project/handlers\"
)

func main() {
  err := godotenv.Load(\".env\")
  if err != nil {
    log.Fatal(\"failed to load .env\")
  }
  
  app := fiber.New()

  setupRoutes(app)

  port := os.Getenv(\"PORT\")
  if port == \"\" {
    port = \"4000\"
  }
  log.Fatal(app.Listen(\":\" + port))
}

func setupRoutes(app *fiber.App) {
  // Handle Frontend routes
  handlers.HandleFrontRoutes(app)

  // Handle API routes
  api := app.Group(\"/api\")

  api.Get(\"/hello\", handlers.HandleHello)
}
" > main.go

touch .env
mkdir handlers
cd handlers
touch handlers.go
echo "package handlers

import (
  \"path/filepath\"
  \"strings\"

  \"github.com/gofiber/fiber/v2\"
)

func HandleFrontRoutes(app *fiber.App) {
  // Serve static files from the dist directory
  app.Static(\"/\", \"../client/dist\", fiber.Static{
    CacheDuration: 200,
  })

  // Not handling api routes here
  app.Use(func(c *fiber.Ctx) error {
    path := c.Path()

    if strings.HasPrefix(path, \"/api\") {
      return c.Next()
    }

    if strings.Contains(path, \".\") {
      return c.Next()
    }

    return c.SendFile(filepath.Join(\"..\", \"client\", \"dist\", \"index.html\"))
  })
}

func HandleHello(c *fiber.Ctx) error {
  return c.JSON(fiber.Map{\"hello\": \"world\"})
}
" > handlers.go

go mod tidy

go install github.com/air-verse/air@latest

cd ../..

# SETUP VITE
curl -fsSL https://get.pnpm.io/install.sh | sh -
source ~/.bashrc

pnpm create vite client --template solid-ts
cd client
pnpm i
pnpm i @solidjs/router
pnpm i -D tailwindcss postcss autoprefixer
pnpm dlx tailwindcss init -p
echo "/** @type {import('tailwindcss').Config} */
export default {
  content: [
    './src/**/*.{js,jsx,ts,tsx}',
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
" > tailwind.config.js

echo "import { defineConfig } from 'vite'
import solid from 'vite-plugin-solid'

export default defineConfig({
  plugins: [solid()],
  css: {
    postcss: './postcss.config.js',
  },
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:4000',
        changeOrigin: true
      }
    }
  }
}) " > vite.config.ts

# SRC
cd src

echo "@tailwind base;
@tailwind components;
@tailwind utilities;
" > index.css

rm -rf App.css

echo "/* @refresh reload */
import { render } from 'solid-js/web'
import './index.css'
import { Route, Router } from '@solidjs/router'
import Layout from './Layout.tsx'

const root = document.getElementById('root')

render(() => (
  <Router>
    <Route path='/' component={Layout}>
      <Route path='/' component={() => <h1>Home</h1>} />
      <Route path='/about' component={() => <h1>About</h1>} />
      <Route path='*' component={() => <h1>404 not found</h1>} />
    </Route>
  </Router>
), root!)
" > index.tsx

touch Layout.tsx
echo "import { Component, JSX } from 'solid-js'

type LayoutProps = {
  children?: JSX.Element
}

const Layout: Component<LayoutProps> = (props) => {
  return (
    <div class=\"flex bg-zinc-800 text-white h-screen\">
      <div class='bg-zinc-900 w-64 flex flex-col underline'>
        <a href='/'>Home</a>
        <a href='/about'>About</a>
        <a href='1234'>404</a>
        <a href='http://localhost:4000/api/hello' target='blank'>API</a>
      </div>
        {props.children}
    </div>
  )
}

export default Layout" > Layout.tsx

